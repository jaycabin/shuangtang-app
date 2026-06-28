package repository

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/shuangtang-app/backend/internal/model"
)

type SystemConfigRepo struct {
	pool *pgxpool.Pool
}

func NewSystemConfigRepo(pool *pgxpool.Pool) *SystemConfigRepo {
	return &SystemConfigRepo{pool: pool}
}

func (r *SystemConfigRepo) Get(ctx context.Context, key string) (*model.SystemConfig, error) {
	query := `SELECT id, key, value, description, updated_at FROM system_configs WHERE key = $1`
	config := &model.SystemConfig{}
	err := r.pool.QueryRow(ctx, query, key).Scan(&config.ID, &config.Key, &config.Value, &config.Description, &config.UpdatedAt)
	if err != nil {
		return nil, err
	}
	return config, nil
}

func (r *SystemConfigRepo) Set(ctx context.Context, key, value string) error {
	query := `INSERT INTO system_configs (key, value, updated_at) VALUES ($1, $2, NOW())
	          ON CONFLICT (key) DO UPDATE SET value = $2, updated_at = NOW()`
	_, err := r.pool.Exec(ctx, query, key, value)
	return err
}

func (r *SystemConfigRepo) List(ctx context.Context) ([]model.SystemConfig, error) {
	query := `SELECT id, key, value, description, updated_at FROM system_configs ORDER BY key`
	rows, err := r.pool.Query(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var configs []model.SystemConfig
	for rows.Next() {
		var c model.SystemConfig
		if err := rows.Scan(&c.ID, &c.Key, &c.Value, &c.Description, &c.UpdatedAt); err != nil {
			return nil, err
		}
		configs = append(configs, c)
	}
	return configs, nil
}
