package service

import (
	"bytes"
	"fmt"
	"html/template"
	"os"
	"path/filepath"

	"github.com/shuangtang-app/backend/internal/config"
	"github.com/shuangtang-app/backend/internal/i18n"
	"gopkg.in/gomail.v2"
)

type EmailService struct {
	cfg    *config.SMTPConfig
	dialer *gomail.Dialer
}

func NewEmailService(cfg *config.SMTPConfig) *EmailService {
	s := &EmailService{cfg: cfg}
	if cfg.Host != "" {
		s.dialer = gomail.NewDialer(cfg.Host, cfg.Port, cfg.User, cfg.Pass)
	}
	return s
}

func (s *EmailService) SendVerificationCode(to, code, lang string, expireMinutes int) error {
	subject := i18n.T(lang, "email.verification.subject")
	body := i18n.T(lang, "email.verification.body", map[string]string{
		"code":   code,
		"expire": fmt.Sprintf("%d", expireMinutes),
	})

	return s.send(to, subject, body)
}

func (s *EmailService) SendResetPasswordCode(to, code, lang string, expireMinutes int) error {
	subject := i18n.T(lang, "email.reset_password.subject")
	body := i18n.T(lang, "email.reset_password.body", map[string]string{
		"code":   code,
		"expire": fmt.Sprintf("%d", expireMinutes),
	})

	return s.send(to, subject, body)
}

func (s *EmailService) SendTemplateEmail(to, subject, templateName string, data interface{}, lang string) error {
	tmplPath := filepath.Join("web", "templates", "emails", lang, templateName+".html")
	if _, err := os.Stat(tmplPath); os.IsNotExist(err) {
		tmplPath = filepath.Join("web", "templates", "emails", "zh", templateName+".html")
	}

	tmpl, err := template.ParseFiles(tmplPath)
	if err != nil {
		return fmt.Errorf("parse email template: %w", err)
	}

	var buf bytes.Buffer
	if err := tmpl.Execute(&buf, data); err != nil {
		return fmt.Errorf("execute email template: %w", err)
	}

	return s.send(to, subject, buf.String())
}

func (s *EmailService) send(to, subject, body string) error {
	if s.dialer == nil {
		return fmt.Errorf("SMTP not configured")
	}

	m := gomail.NewMessage()
	m.SetHeader("From", s.cfg.From)
	m.SetHeader("To", to)
	m.SetHeader("Subject", subject)
	m.SetBody("text/html", body)

	return s.dialer.DialAndSend(m)
}
