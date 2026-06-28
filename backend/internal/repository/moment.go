package repository

import (
	"context"
	"encoding/json"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/shuangtang-app/backend/internal/model"
)

type MomentRepo struct {
	pool *pgxpool.Pool
}

func NewMomentRepo(pool *pgxpool.Pool) *MomentRepo {
	return &MomentRepo{pool: pool}
}

func (r *MomentRepo) Create(ctx context.Context, m *model.Moment) error {
	images, _ := json.Marshal(m.ImageURLs)
	loc, _ := json.Marshal(m.Location)

	query := `INSERT INTO moments (id, couple_id, author_id, type, content, image_urls, location, mood_tag, created_at, updated_at)
	          VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW(), NOW()) RETURNING created_at, updated_at`
	return r.pool.QueryRow(ctx, query,
		m.ID, m.CoupleID, m.AuthorID, m.Type, m.Content,
		images, loc, m.MoodTag,
	).Scan(&m.CreatedAt, &m.UpdatedAt)
}

func (r *MomentRepo) GetTimeline(ctx context.Context, coupleID uuid.UUID, cursor time.Time, limit int) ([]model.Moment, error) {
	query := `SELECT id, couple_id, author_id, type, content, image_urls, location, mood_tag, is_pinned, created_at, updated_at
	          FROM moments WHERE couple_id = $1 AND created_at < $2
	          ORDER BY is_pinned DESC, created_at DESC LIMIT $3`
	rows, err := r.pool.Query(ctx, query, coupleID, cursor, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var moments []model.Moment
	for rows.Next() {
		var m model.Moment
		var images []byte
		var loc []byte
		if err := rows.Scan(&m.ID, &m.CoupleID, &m.AuthorID, &m.Type, &m.Content,
			&images, &loc, &m.MoodTag, &m.IsPinned, &m.CreatedAt, &m.UpdatedAt); err != nil {
			return nil, err
		}
		json.Unmarshal(images, &m.ImageURLs)
		if loc != nil {
			json.Unmarshal(loc, &m.Location)
		}
		moments = append(moments, m)
	}
	return moments, nil
}

func (r *MomentRepo) FindByID(ctx context.Context, id uuid.UUID) (*model.Moment, error) {
	query := `SELECT id, couple_id, author_id, type, content, image_urls, location, mood_tag, is_pinned, created_at, updated_at
	          FROM moments WHERE id = $1`
	var m model.Moment
	var images []byte
	var loc []byte
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&m.ID, &m.CoupleID, &m.AuthorID, &m.Type, &m.Content,
		&images, &loc, &m.MoodTag, &m.IsPinned, &m.CreatedAt, &m.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	json.Unmarshal(images, &m.ImageURLs)
	if loc != nil {
		json.Unmarshal(loc, &m.Location)
	}
	return &m, nil
}
