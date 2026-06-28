package repository

import (
	"context"
	"encoding/json"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/shuangtang-app/backend/internal/model"
)

type AnniversaryRepo struct {
	pool *pgxpool.Pool
}

func NewAnniversaryRepo(pool *pgxpool.Pool) *AnniversaryRepo {
	return &AnniversaryRepo{pool: pool}
}

func (r *AnniversaryRepo) Create(ctx context.Context, a *model.Anniversary) error {
	title, _ := json.Marshal(a.Title)
	query := `INSERT INTO anniversaries (id, couple_id, title, date, is_recurring, remind_before, icon, created_by, created_at, updated_at)
	          VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW(), NOW()) RETURNING created_at, updated_at`
	return r.pool.QueryRow(ctx, query, a.ID, a.CoupleID, title, a.Date, a.IsRecurring, a.RemindBefore, a.Icon, a.CreatedBy).
		Scan(&a.CreatedAt, &a.UpdatedAt)
}

func (r *AnniversaryRepo) ListByCouple(ctx context.Context, coupleID uuid.UUID) ([]model.Anniversary, error) {
	query := `SELECT id, couple_id, title, date, is_recurring, remind_before, icon, created_by, created_at, updated_at
	          FROM anniversaries WHERE couple_id = $1 ORDER BY date ASC`
	rows, err := r.pool.Query(ctx, query, coupleID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var anniversaries []model.Anniversary
	for rows.Next() {
		var a model.Anniversary
		var titleJSON []byte
		if err := rows.Scan(&a.ID, &a.CoupleID, &titleJSON, &a.Date, &a.IsRecurring,
			&a.RemindBefore, &a.Icon, &a.CreatedBy, &a.CreatedAt, &a.UpdatedAt); err != nil {
			return nil, err
		}
		json.Unmarshal(titleJSON, &a.Title)
		anniversaries = append(anniversaries, a)
	}
	return anniversaries, nil
}
