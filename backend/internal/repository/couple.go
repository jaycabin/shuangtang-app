package repository

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/shuangtang-app/backend/internal/model"
)

type CoupleRepo struct {
	pool *pgxpool.Pool
}

func NewCoupleRepo(pool *pgxpool.Pool) *CoupleRepo {
	return &CoupleRepo{pool: pool}
}

func (r *CoupleRepo) Create(ctx context.Context, couple *model.Couple) error {
	query := `INSERT INTO couples (id, user1_id, invitation_code, status, created_at, updated_at)
	          VALUES ($1, $2, $3, 'pending', NOW(), NOW()) RETURNING created_at, updated_at`
	return r.pool.QueryRow(ctx, query, couple.ID, couple.User1ID, couple.InvitationCode).
		Scan(&couple.CreatedAt, &couple.UpdatedAt)
}

func (r *CoupleRepo) FindByInvitationCode(ctx context.Context, code string) (*model.Couple, error) {
	query := `SELECT id, user1_id, user2_id, invitation_code, status, started_at, created_at, updated_at
	          FROM couples WHERE invitation_code = $1`
	couple := &model.Couple{}
	err := r.pool.QueryRow(ctx, query, code).Scan(
		&couple.ID, &couple.User1ID, &couple.User2ID,
		&couple.InvitationCode, &couple.Status, &couple.StartedAt,
		&couple.CreatedAt, &couple.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return couple, nil
}

func (r *CoupleRepo) Join(ctx context.Context, coupleID, userID uuid.UUID) error {
	query := `UPDATE couples SET user2_id = $1, status = 'active', started_at = NOW(), updated_at = NOW() WHERE id = $2 AND status = 'pending'`
	tag, err := r.pool.Exec(ctx, query, userID, coupleID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return pgx.ErrNoRows
	}
	return nil
}

func (r *CoupleRepo) FindByUserID(ctx context.Context, userID uuid.UUID) (*model.Couple, error) {
	query := `SELECT id, user1_id, user2_id, invitation_code, status, started_at, created_at, updated_at
	          FROM couples WHERE (user1_id = $1 OR user2_id = $1) AND status = 'active'`
	couple := &model.Couple{}
	err := r.pool.QueryRow(ctx, query, userID).Scan(
		&couple.ID, &couple.User1ID, &couple.User2ID,
		&couple.InvitationCode, &couple.Status, &couple.StartedAt,
		&couple.CreatedAt, &couple.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return couple, nil
}

func (r *CoupleRepo) GetPartnerID(ctx context.Context, coupleID, userID uuid.UUID) (uuid.UUID, error) {
	query := `SELECT CASE WHEN user1_id = $2 THEN user2_id ELSE user1_id END FROM couples WHERE id = $1`
	var partnerID uuid.UUID
	err := r.pool.QueryRow(ctx, query, coupleID, userID).Scan(&partnerID)
	return partnerID, err
}
