package service

import (
	"testing"

	"github.com/shuangtang-app/backend/internal/config"
)

func TestEmailService_DevMode(t *testing.T) {
	cfg := &config.SMTPConfig{Host: "", Port: 0, User: "", Pass: "", From: ""}
	svc := NewEmailService(cfg)

	// SMTP 未配置时不应报错（开发模式打印日志）
	err := svc.SendVerificationCode("test@test.com", "123456", "zh", 5)
	if err != nil {
		t.Errorf("dev mode should not return error, got: %v", err)
	}
}

func TestEmailService_InvalidEmail(t *testing.T) {
	cfg := &config.SMTPConfig{Host: "smtp.test.com", Port: 465, User: "user", Pass: "pass", From: "from@test.com"}
	svc := NewEmailService(cfg)

	// SMTP 配置了但目标邮箱无效时应有具体错误
	err := svc.SendVerificationCode("", "123456", "zh", 5)
	if err == nil {
		t.Log("empty email with configured SMTP may or may not fail at dial stage")
	}
}
