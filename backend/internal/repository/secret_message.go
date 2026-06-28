package repository

import (
	"context"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/shuangtang-app/backend/internal/model"
)

type SecretMessageRepo struct {
	pool *pgxpool.Pool
}

func NewSecretMessageRepo(pool *pgxpool.Pool) *SecretMessageRepo {
	return &SecretMessageRepo{pool: pool}
}

func (r *SecretMessageRepo) Create(ctx context.Context, msg *model.SecretMessage) error {
	query := `INSERT INTO secret_messages (id, couple_id, sender_id, content, encrypted_content, created_at)
	          VALUES ($1, $2, $3, $4, $5, NOW()) RETURNING created_at`
	return r.pool.QueryRow(ctx, query, msg.ID, msg.CoupleID, msg.SenderID, msg.Content, msg.EncryptedContent).
		Scan(&msg.CreatedAt)
}

func (r *SecretMessageRepo) ListByCouple(ctx context.Context, coupleID uuid.UUID, limit, offset int) ([]model.SecretMessage, error) {
	query := `SELECT id, couple_id, sender_id, content, encrypted_content, is_read, read_at, created_at
	          FROM secret_messages WHERE couple_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3`
	rows, err := r.pool.Query(ctx, query, coupleID, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var messages []model.SecretMessage
	for rows.Next() {
		var msg model.SecretMessage
		if err := rows.Scan(&msg.ID, &msg.CoupleID, &msg.SenderID, &msg.Content,
			&msg.EncryptedContent, &msg.IsRead, &msg.ReadAt, &msg.CreatedAt); err != nil {
			return nil, err
		}
		messages = append(messages, msg)
	}
	return messages, nil
}

func (r *SecretMessageRepo) MarkAsRead(ctx context.Context, id uuid.UUID) error {
	query := `UPDATE secret_messages SET is_read = true, read_at = NOW() WHERE id = $1`
	_, err := r.pool.Exec(ctx, query, id)
	return err
}
