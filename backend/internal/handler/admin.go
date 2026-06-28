package handler

import (
	"crypto/sha256"
	"encoding/hex"
	"html/template"
	"net/http"
	"sync"

	"github.com/gin-gonic/gin"
	"github.com/gin-gonic/gin/render"
	"github.com/shuangtang-app/backend/internal/config"
	"github.com/shuangtang-app/backend/internal/i18n"
	"github.com/shuangtang-app/backend/internal/repository"
)

type AdminHandler struct {
	cfg         *config.AdminConfig
	systemCfg   *repository.SystemConfigRepo
	mu          sync.Mutex
	sessionKey  string
	templates   *template.Template
}

func NewAdminHandler(cfg *config.AdminConfig, systemCfg *repository.SystemConfigRepo) *AdminHandler {
	h := &AdminHandler{
		cfg:       cfg,
		systemCfg: systemCfg,
	}
	h.loadTemplates()
	return h
}

func (h *AdminHandler) loadTemplates() {
	tmpl := template.New("")
	template.Must(tmpl.ParseGlob("web/templates/admin/*.html"))
	h.templates = tmpl
}

func (h *AdminHandler) render(c *gin.Context, name string, data gin.H) {
	if data == nil {
		data = gin.H{}
	}
	data["lang"] = "zh"
	c.HTML(http.StatusOK, name, data)
}

func (h *AdminHandler) LoginPage(c *gin.Context) {
	if h.isLoggedIn(c) {
		c.Redirect(http.StatusFound, "/admin/dashboard")
		return
	}
	h.render(c, "login.html", gin.H{
		"title": "管理员登录 - 双糖控制台",
	})
}

func (h *AdminHandler) Login(c *gin.Context) {
	email := c.PostForm("email")
	password := c.PostForm("password")

	if email == h.cfg.Email && password == h.cfg.Password {
		h.mu.Lock()
		h.sessionKey = h.generateSessionKey()
		h.mu.Unlock()

		c.SetCookie("admin_session", h.sessionKey, 86400, "/admin", "", false, true)
		c.Redirect(http.StatusFound, "/admin/dashboard")
		return
	}

	h.render(c, "login.html", gin.H{
		"title": "管理员登录 - 双糖控制台",
		"error": "邮箱或密码错误",
	})
}

func (h *AdminHandler) Dashboard(c *gin.Context) {
	if !h.isLoggedIn(c) {
		c.Redirect(http.StatusFound, "/admin")
		return
	}
	h.render(c, "dashboard.html", gin.H{
		"title": "仪表盘 - 双糖控制台",
	})
}

func (h *AdminHandler) SMTPPage(c *gin.Context) {
	if !h.isLoggedIn(c) {
		c.Redirect(http.StatusFound, "/admin")
		return
	}

	configs := make(map[string]string)
	for _, key := range []string{"smtp_host", "smtp_port", "smtp_user", "smtp_pass", "smtp_from"} {
		cfg, err := h.systemCfg.Get(c.Request.Context(), key)
		if err == nil {
			configs[key] = cfg.Value
		}
	}

	h.render(c, "smtp.html", gin.H{
		"title":   "SMTP 配置 - 双糖控制台",
		"configs": configs,
	})
}

func (h *AdminHandler) SaveSMTP(c *gin.Context) {
	if !h.isLoggedIn(c) {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未登录"})
		return
	}

	keys := []string{"smtp_host", "smtp_port", "smtp_user", "smtp_pass", "smtp_from"}
	for _, key := range keys {
		value := c.PostForm(key)
		if value != "" {
			h.systemCfg.Set(c.Request.Context(), key, value)
		}
	}

	c.Redirect(http.StatusFound, "/admin/smtp?success=1")
}

func (h *AdminHandler) TestSMTP(c *gin.Context) {
	if !h.isLoggedIn(c) {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未登录"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "测试邮件发送功能（需要配置有效SMTP）",
	})
}

func (h *AdminHandler) TemplatesPage(c *gin.Context) {
	if !h.isLoggedIn(c) {
		c.Redirect(http.StatusFound, "/admin")
		return
	}
	h.render(c, "templates.html", gin.H{
		"title": "邮件模板 - 双糖控制台",
	})
}

func (h *AdminHandler) SaveTemplates(c *gin.Context) {
	if !h.isLoggedIn(c) {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未登录"})
		return
	}
	c.Redirect(http.StatusFound, "/admin/templates?success=1")
}

func (h *AdminHandler) SettingsPage(c *gin.Context) {
	if !h.isLoggedIn(c) {
		c.Redirect(http.StatusFound, "/admin")
		return
	}

	configs := make(map[string]string)
	for _, key := range []string{"app_name", "app_logo_url", "file_storage", "minio_endpoint", "minio_access_key", "minio_bucket"} {
		cfg, err := h.systemCfg.Get(c.Request.Context(), key)
		if err == nil {
			configs[key] = cfg.Value
		}
	}

	h.render(c, "settings.html", gin.H{
		"title":   "系统配置 - 双糖控制台",
		"configs": configs,
	})
}

func (h *AdminHandler) SaveSettings(c *gin.Context) {
	if !h.isLoggedIn(c) {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未登录"})
		return
	}

	keys := []string{"app_name", "app_logo_url", "file_storage", "minio_endpoint", "minio_access_key", "minio_secret_key", "minio_bucket"}
	for _, key := range keys {
		value := c.PostForm(key)
		if value != "" {
			h.systemCfg.Set(c.Request.Context(), key, value)
		}
	}

	c.Redirect(http.StatusFound, "/admin/settings?success=1")
}

func (h *AdminHandler) Logout(c *gin.Context) {
	h.mu.Lock()
	h.sessionKey = ""
	h.mu.Unlock()
	c.SetCookie("admin_session", "", -1, "/admin", "", false, true)
	c.Redirect(http.StatusFound, "/admin")
}

func (h *AdminHandler) isLoggedIn(c *gin.Context) bool {
	cookie, err := c.Cookie("admin_session")
	if err != nil {
		return false
	}
	h.mu.Lock()
	defer h.mu.Unlock()
	return cookie != "" && cookie == h.sessionKey
}

func (h *AdminHandler) generateSessionKey() string {
	hash := sha256.Sum256([]byte(hex.EncodeToString([]byte("shuangtang-admin-" + h.cfg.Email))))
	return hex.EncodeToString(hash[:])
}
