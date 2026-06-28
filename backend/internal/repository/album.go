package repository

import (
	"context"
	"encoding/json"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/shuangtang-app/backend/internal/model"
)

type AlbumRepo struct {
	pool *pgxpool.Pool
}

func NewAlbumRepo(pool *pgxpool.Pool) *AlbumRepo {
	return &AlbumRepo{pool: pool}
}

func (r *AlbumRepo) Create(ctx context.Context, album *model.Album) error {
	loc, _ := json.Marshal(album.Location)
	query := `INSERT INTO albums (id, couple_id, uploader_id, image_url, thumbnail_url, taken_at, location, tags, width, height, file_size, created_at)
	          VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW()) RETURNING created_at`
	return r.pool.QueryRow(ctx, query, album.ID, album.CoupleID, album.UploaderID, album.ImageURL,
		album.ThumbnailURL, album.TakenAt, loc, album.Tags, album.Width, album.Height, album.FileSize).Scan(&album.CreatedAt)
}

func (r *AlbumRepo) ListByCouple(ctx context.Context, coupleID uuid.UUID, limit, offset int) ([]model.Album, error) {
	query := `SELECT id, couple_id, uploader_id, image_url, thumbnail_url, taken_at, location, tags, width, height, file_size, created_at
	          FROM albums WHERE couple_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3`
	rows, err := r.pool.Query(ctx, query, coupleID, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var albums []model.Album
	for rows.Next() {
		var a model.Album
		var loc []byte
		if err := rows.Scan(&a.ID, &a.CoupleID, &a.UploaderID, &a.ImageURL, &a.ThumbnailURL,
			&a.TakenAt, &loc, &a.Tags, &a.Width, &a.Height, &a.FileSize, &a.CreatedAt); err != nil {
			return nil, err
		}
		if loc != nil {
			json.Unmarshal(loc, &a.Location)
		}
		albums = append(albums, a)
	}
	return albums, nil
}
