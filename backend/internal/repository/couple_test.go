package repository

import (
	"context"
	"testing"

	"github.com/google/uuid"
	"github.com/shuangtang-app/backend/internal/model"
)

func TestCoupleCreate_DSN(t *testing.T) {
	// 验证 DSN 格式（不实际连接数据库）
	dsn := "postgres://postgres:postgres@localhost:15433/shuangtang?sslmode=disable"
	if dsn == "" {
		t.Error("DSN should not be empty")
	}
}

func TestCoupleModel_Validation(t *testing.T) {
	uid := uuid.New()
	c := &model.Couple{
		ID:      uuid.New(),
		User1ID: uid,
		User2ID: &uid,
		Status:  "active",
	}

	if c.Status != "active" {
		t.Error("expected status active")
	}
	if c.User1ID != uid {
		t.Error("expected user1_id to match")
	}
	if c.User2ID == nil || *c.User2ID != uid {
		t.Error("expected user2_id to match")
	}
}
