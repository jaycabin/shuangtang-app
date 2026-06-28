package repository

import (
	"context"
	"encoding/json"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/shuangtang-app/backend/internal/model"
)

type WishlistRepo struct {
	pool *pgxpool.Pool
}

func NewWishlistRepo(pool *pgxpool.Pool) *WishlistRepo {
	return &WishlistRepo{pool: pool}
}

func (r *WishlistRepo) Create(ctx context.Context, item *model.WishlistItem) error {
	title, _ := json.Marshal(item.Title)
	query := `INSERT INTO wishlist_items (id, couple_id, creator_id, title, description, image_url, price, status, created_at, updated_at)
	          VALUES ($1, $2, $3, $4, $5, $6, $7, 'pending', NOW(), NOW()) RETURNING created_at, updated_at`
	return r.pool.QueryRow(ctx, query, item.ID, item.CoupleID, item.CreatorID, title,
		item.Description, item.ImageURL, item.Price).Scan(&item.CreatedAt, &item.UpdatedAt)
}

func (r *WishlistRepo) ListByCouple(ctx context.Context, coupleID uuid.UUID) ([]model.WishlistItem, error) {
	query := `SELECT id, couple_id, creator_id, title, description, image_url, price, status, claimed_by, completed_at, created_at, updated_at
	          FROM wishlist_items WHERE couple_id = $1 ORDER BY created_at DESC`
	rows, err := r.pool.Query(ctx, query, coupleID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []model.WishlistItem
	for rows.Next() {
		var item model.WishlistItem
		var titleJSON []byte
		if err := rows.Scan(&item.ID, &item.CoupleID, &item.CreatorID, &titleJSON,
			&item.Description, &item.ImageURL, &item.Price, &item.Status,
			&item.ClaimedBy, &item.CompletedAt, &item.CreatedAt, &item.UpdatedAt); err != nil {
			return nil, err
		}
		json.Unmarshal(titleJSON, &item.Title)
		items = append(items, item)
	}
	return items, nil
}

func (r *WishlistRepo) Claim(ctx context.Context, id, userID uuid.UUID) error {
	query := `UPDATE wishlist_items SET status = 'claimed', claimed_by = $1, updated_at = NOW() WHERE id = $2 AND status = 'pending'`
	_, err := r.pool.Exec(ctx, query, userID, id)
	return err
}

func (r *WishlistRepo) Complete(ctx context.Context, id uuid.UUID) error {
	query := `UPDATE wishlist_items SET status = 'completed', completed_at = NOW(), updated_at = NOW() WHERE id = $1`
	_, err := r.pool.Exec(ctx, query, id)
	return err
}
