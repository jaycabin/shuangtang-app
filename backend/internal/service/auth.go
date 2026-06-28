package service

import (
	"context"
	"fmt"
	"math/rand"
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
	rateLimitKey := fmt.Sprintf("code:rate:%s", email)
	exists, _ := s.redis.Exists(ctx, rateLimitKey).Result()
	if exists > 0 {
		return fmt.Errorf("too_frequent")
	}

	code := fmt.Sprintf("%06d", rand.Intn(1000000))

	codeKey := fmt.Sprintf("code:verification:%s", email)
	if err := s.redis.Set(ctx, codeKey, code, 5*time.Minute).Err(); err != nil {
		return err
	}

	if err := s.redis.Set(ctx, rateLimitKey, "1", 60*time.Second).Err(); err != nil {
		return err
	}

	return s.emailSvc.SendVerificationCode(email, code, lang, 5)
}

func (s *AuthService) VerifyCode(ctx context.Context, email, code string) error {
	codeKey := fmt.Sprintf("code:verification:%s", email)
	stored, err := s.redis.Get(ctx, codeKey).Result()
	if err == redis.Nil {
		return fmt.Errorf("code_expired")
	}
	if err != nil {
		return err
	}
	if stored != code {
		return fmt.Errorf("code_invalid")
	}
	s.redis.Del(ctx, codeKey)
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
