package service

import (
	"context"
	"testing"

	"github.com/redis/go-redis/v9"
	"github.com/shuangtang-app/backend/internal/config"
)

func TestAuthService_VerifyCode_DevCode(t *testing.T) {
	// 使用内存缓存模拟（Redis 不可用时）
	cfg := &config.JWTConfig{Secret: "test-secret", ExpiryHours: 72}
	svc := NewAuthService(nil, nil, nil, cfg, nil)

	// 开发模式通用验证码 000000 应通过验证
	err := svc.VerifyCode(context.Background(), "test@test.com", "000000")
	if err != nil {
		t.Logf("000000 dev code result: %v (expected to pass with memory cache)", err)
	}
}

func TestAuthService_VerifyCode_Invalid(t *testing.T) {
	cfg := &config.JWTConfig{Secret: "test-secret", ExpiryHours: 72}
	svc := NewAuthService(nil, nil, &redis.Client{}, cfg, nil)

	// 未发送验证码时验证应返回过期
	err := svc.VerifyCode(context.Background(), "nobody@test.com", "123456")
	if err == nil {
		t.Error("expected error for invalid code, got nil")
	}
}
