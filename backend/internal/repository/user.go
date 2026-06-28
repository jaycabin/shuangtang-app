package repository

import (
	"context"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/shuangtang-app/backend/internal/model"
)

type UserRepo struct {
	pool *pgxpool.Pool
}

func NewUserRepo(pool *pgxpool.Pool) *UserRepo {
	return &UserRepo{pool: pool}
}

func (r *UserRepo) Create(ctx context.Context, user *model.User) error {
	query := `INSERT INTO users (id, email, password_hash, nickname, preferred_language)
	          VALUES ($1, $2, $3, $4, $5) RETURNING created_at, updated_at`
	return r.pool.QueryRow(ctx, query,
		user.ID, user.Email, user.PasswordHash, user.Nickname, user.PreferredLanguage,
	).Scan(&user.CreatedAt, &user.UpdatedAt)
}

func (r *UserRepo) FindByEmail(ctx context.Context, email string) (*model.User, error) {
	query := `SELECT id, email, password_hash, nickname, avatar_url, preferred_language, is_admin, created_at, updated_at
	          FROM users WHERE email = $1`
	user := &model.User{}
	err := r.pool.QueryRow(ctx, query, email).Scan(
		&user.ID, &user.Email, &user.PasswordHash, &user.Nickname,
		&user.AvatarURL, &user.PreferredLanguage, &user.IsAdmin,
		&user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return user, nil
}

func (r *UserRepo) FindByID(ctx context.Context, id uuid.UUID) (*model.User, error) {
	query := `SELECT id, email, password_hash, nickname, avatar_url, preferred_language, is_admin, created_at, updated_at
	          FROM users WHERE id = $1`
	user := &model.User{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&user.ID, &user.Email, &user.PasswordHash, &user.Nickname,
		&user.AvatarURL, &user.PreferredLanguage, &user.IsAdmin,
		&user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return user, nil
}

func (r *UserRepo) UpdatePassword(ctx context.Context, email, passwordHash string) error {
	query := `UPDATE users SET password_hash = $1, updated_at = NOW() WHERE email = $2`
	_, err := r.pool.Exec(ctx, query, passwordHash, email)
	return err
}

func (r *UserRepo) UpdateNickname(ctx context.Context, userID uuid.UUID, nickname string) error {
	query := `UPDATE users SET nickname = $1, updated_at = NOW() WHERE id = $2`
	_, err := r.pool.Exec(ctx, query, nickname, userID)
	return err
}

func (r *UserRepo) UpdateLanguage(ctx context.Context, userID uuid.UUID, lang string) error {
	query := `UPDATE users SET preferred_language = $1, updated_at = NOW() WHERE id = $2`
	_, err := r.pool.Exec(ctx, query, lang, userID)
	return err
}

func (r *UserRepo) UpdateAvatar(ctx context.Context, userID uuid.UUID, avatarURL string) error {
	query := `UPDATE users SET avatar_url = $1, updated_at = NOW() WHERE id = $2`
	_, err := r.pool.Exec(ctx, query, avatarURL, userID)
	return err
}

func (r *UserRepo) CountByEmail(ctx context.Context, email string) (int, error) {
	var count int
	err := r.pool.QueryRow(ctx, "SELECT COUNT(*) FROM users WHERE email = $1", email).Scan(&count)
	return count, err
}
