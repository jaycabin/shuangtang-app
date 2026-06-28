package service

import (
	"context"
	"fmt"
	"math/rand"
	"sync"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"
	"github.com/shuangtang-app/backend/internal/config"
	"github.com/shuangtang-app/backend/internal/middleware"
	"github.com/shuangtang-app/backend/internal/model"
	"github.com/shuangtang-app/backend/internal/repository"
	"golang.org/x/crypto/bcrypt"
)

type AuthService struct {
	userRepo   *repository.UserRepo
	coupleRepo *repository.CoupleRepo
	redis      *redis.Client
	cfg        *config.JWTConfig
	emailSvc   *EmailService
	// 内存缓存（Redis 不可用时降级）
	memoryCache sync.Map
}

func NewAuthService(userRepo *repository.UserRepo, coupleRepo *repository.CoupleRepo,
	redis *redis.Client, cfg *config.JWTConfig, emailSvc *EmailService) *AuthService {
	return &AuthService{
		userRepo:   userRepo,
		coupleRepo: coupleRepo,
		redis:      redis,
		cfg:        cfg,
		emailSvc:   emailSvc,
	}
}

func (s *AuthService) SendVerificationCode(ctx context.Context, email, lang string) error {
	rateLimitKey := "rate:" + email
	if s.redis != nil {
		exists, _ := s.redis.Exists(ctx, rateLimitKey).Result()
		if exists > 0 {
			return fmt.Errorf("too_frequent")
		}
	} else {
		if _, ok := s.memoryCache.Load(rateLimitKey); ok {
			return fmt.Errorf("too_frequent")
		}
	}

	code := fmt.Sprintf("%06d", rand.Intn(1000000))
	codeKey := "code:" + email

	if s.redis != nil {
		s.redis.Set(ctx, codeKey, code, 5*time.Minute)
		s.redis.Set(ctx, rateLimitKey, "1", 60*time.Second)
	} else {
		s.memoryCache.Store(codeKey, code)
		s.memoryCache.Store(rateLimitKey, "1")
		go func() { time.Sleep(5 * time.Minute); s.memoryCache.Delete(codeKey) }()
		go func() { time.Sleep(60 * time.Second); s.memoryCache.Delete(rateLimitKey) }()
	}

	return s.emailSvc.SendVerificationCode(email, code, lang, 5)
}

func (s *AuthService) VerifyCode(ctx context.Context, email, code string) error {
	codeKey := "code:" + email
	var stored string

	if s.redis != nil {
		var err error
		stored, err = s.redis.Get(ctx, codeKey).Result()
		if err == redis.Nil {
			return fmt.Errorf("code_expired")
		}
		if err != nil {
			return err
		}
	} else {
		val, ok := s.memoryCache.Load(codeKey)
		if !ok {
			return fmt.Errorf("code_expired")
		}
		stored = val.(string)
	}

	if stored != code {
		return fmt.Errorf("code_invalid")
	}

	if s.redis != nil {
		s.redis.Del(ctx, codeKey)
	} else {
		s.memoryCache.Delete(codeKey)
	}
	return nil
}

func (s *AuthService) Register(ctx context.Context, req *model.RegisterRequest) error {
	exists, err := s.userRepo.CountByEmail(ctx, req.Email)
	if err != nil {
		return err
	}
	if exists > 0 {
		return fmt.Errorf("email_exists")
	}

	if err := s.VerifyCode(ctx, req.Email, req.VerificationCode); err != nil {
		return err
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return err
	}

	user := &model.User{
		ID:                uuid.New(),
		Email:             req.Email,
		PasswordHash:      string(hash),
		Nickname:          req.Nickname,
		PreferredLanguage: "zh",
	}

	return s.userRepo.Create(ctx, user)
}

func (s *AuthService) Login(ctx context.Context, req *model.LoginRequest) (string, *model.User, error) {
	user, err := s.userRepo.FindByEmail(ctx, req.Email)
	if err != nil {
		return "", nil, fmt.Errorf("invalid_credentials")
	}

	if req.Password != "" {
		if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
			return "", nil, fmt.Errorf("invalid_credentials")
		}
	} else if req.Code != "" {
		if err := s.VerifyCode(ctx, req.Email, req.Code); err != nil {
			return "", nil, err
		}
	} else {
		return "", nil, fmt.Errorf("invalid_credentials")
	}

	token, err := s.generateToken(user)
	if err != nil {
		return "", nil, err
	}

	return token, user, nil
}

func (s *AuthService) ForgotPassword(ctx context.Context, email, lang string) error {
	_, err := s.userRepo.FindByEmail(ctx, email)
	if err != nil {
		return nil
	}

	return s.SendVerificationCode(ctx, email, lang)
}

func (s *AuthService) ResetPassword(ctx context.Context, req *model.ResetPasswordRequest) error {
	if err := s.VerifyCode(ctx, req.Email, req.Code); err != nil {
		return err
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		return err
	}

	return s.userRepo.UpdatePassword(ctx, req.Email, string(hash))
}

func (s *AuthService) generateToken(user *model.User) (string, error) {
	claims := &middleware.Claims{
		UserID: user.ID.String(),
		Email:  user.Email,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Duration(s.cfg.ExpiryHours) * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(s.cfg.Secret))
}
