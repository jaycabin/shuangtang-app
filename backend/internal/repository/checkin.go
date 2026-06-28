package repository

import (
	"context"
	"encoding/json"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/shuangtang-app/backend/internal/model"
)

type CheckInRepo struct {
	pool *pgxpool.Pool
}

func NewCheckInRepo(pool *pgxpool.Pool) *CheckInRepo {
	return &CheckInRepo{pool: pool}
}

func (r *CheckInRepo) CreateTask(ctx context.Context, t *model.CheckInTask) error {
	title, _ := json.Marshal(t.Title)
	query := `INSERT INTO check_in_tasks (id, couple_id, title, icon, schedule_type, sort_order, is_active, created_by, created_at, updated_at)
	          VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW(), NOW()) RETURNING created_at, updated_at`
	return r.pool.QueryRow(ctx, query, t.ID, t.CoupleID, title, t.Icon, t.ScheduleType, t.SortOrder, t.IsActive, t.CreatedBy).
		Scan(&t.CreatedAt, &t.UpdatedAt)
}

func (r *CheckInRepo) ListTasks(ctx context.Context, coupleID uuid.UUID) ([]model.CheckInTask, error) {
	query := `SELECT id, couple_id, title, icon, schedule_type, sort_order, is_active, created_by, created_at, updated_at
	          FROM check_in_tasks WHERE couple_id = $1 AND is_active = true ORDER BY sort_order ASC`
	rows, err := r.pool.Query(ctx, query, coupleID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var tasks []model.CheckInTask
	for rows.Next() {
		var t model.CheckInTask
		var titleJSON []byte
		if err := rows.Scan(&t.ID, &t.CoupleID, &titleJSON, &t.Icon, &t.ScheduleType,
			&t.SortOrder, &t.IsActive, &t.CreatedBy, &t.CreatedAt, &t.UpdatedAt); err != nil {
			return nil, err
		}
		json.Unmarshal(titleJSON, &t.Title)
		tasks = append(tasks, t)
	}
	return tasks, nil
}

func (r *CheckInRepo) CreateRecord(ctx context.Context, record *model.CheckInRecord) error {
	query := `INSERT INTO check_in_records (id, task_id, user_id, check_date, done_at, note)
	          VALUES ($1, $2, $3, $4, NOW(), $5) RETURNING done_at`
	return r.pool.QueryRow(ctx, query, record.ID, record.TaskID, record.UserID, record.CheckDate, record.Note).
		Scan(&record.DoneAt)
}

func (r *CheckInRepo) GetRecordsByDate(ctx context.Context, taskID uuid.UUID, date time.Time) ([]model.CheckInRecord, error) {
	query := `SELECT id, task_id, user_id, check_date, done_at, note
	          FROM check_in_records WHERE task_id = $1 AND check_date = $2`
	rows, err := r.pool.Query(ctx, query, taskID, date)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var records []model.CheckInRecord
	for rows.Next() {
		var rec model.CheckInRecord
		if err := rows.Scan(&rec.ID, &rec.TaskID, &rec.UserID, &rec.CheckDate, &rec.DoneAt, &rec.Note); err != nil {
			return nil, err
		}
		records = append(records, rec)
	}
	return records, nil
}

func (r *CheckInRepo) GetConsecutiveDays(ctx context.Context, userID uuid.UUID, coupleID uuid.UUID) (int, error) {
	query := `
		WITH daily AS (
			SELECT DISTINCT check_date
			FROM check_in_records r
			JOIN check_in_tasks t ON r.task_id = t.id
			WHERE r.user_id = $1 AND t.couple_id = $2
			ORDER BY check_date DESC
		)
		SELECT COUNT(*) FROM daily
	`
	var count int
	err := r.pool.QueryRow(ctx, query, userID, coupleID).Scan(&count)
	return count, err
}
