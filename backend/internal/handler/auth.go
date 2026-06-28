package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/shuangtang-app/backend/internal/i18n"
	"github.com/shuangtang-app/backend/internal/middleware"
	"github.com/shuangtang-app/backend/internal/model"
	"github.com/shuangtang-app/backend/internal/service"
)

type AuthHandler struct {
	authSvc *service.AuthService
}

func NewAuthHandler(authSvc *service.AuthService) *AuthHandler {
	return &AuthHandler{authSvc: authSvc}
}

func (h *AuthHandler) SendCode(c *gin.Context) {
	lang := middleware.GetLang(c)
	var req model.SendCodeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, model.APIResponse{
			Code:    400,
			Message: i18n.T(lang, "error.invalid_input"),
		})
		return
	}

	if err := h.authSvc.SendVerificationCode(c.Request.Context(), req.Email, lang); err != nil {
		msg := i18n.T(lang, "error.too_frequent")
		if err.Error() != "too_frequent" {
			msg = i18n.T(lang, "error.server_error")
		}
		c.JSON(http.StatusTooManyRequests, model.APIResponse{
			Code:    429,
			Message: msg,
		})
		return
	}

	c.JSON(http.StatusOK, model.APIResponse{
		Code:    200,
		Message: i18n.T(lang, "success.code_sent"),
	})
}

func (h *AuthHandler) Register(c *gin.Context) {
	lang := middleware.GetLang(c)
	var req model.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, model.APIResponse{
			Code:    400,
			Message: i18n.T(lang, "error.invalid_input"),
		})
		return
	}

	if err := h.authSvc.Register(c.Request.Context(), &req); err != nil {
		msg := i18n.T(lang, "error.server_error")
		switch err.Error() {
		case "email_exists":
			msg = i18n.T(lang, "error.email_exists")
		case "code_expired":
			msg = i18n.T(lang, "error.code_expired")
		case "code_invalid":
			msg = i18n.T(lang, "error.code_invalid")
		}
		c.JSON(http.StatusBadRequest, model.APIResponse{Code: 400, Message: msg})
		return
	}

	c.JSON(http.StatusOK, model.APIResponse{
		Code:    200,
		Message: i18n.T(lang, "success.registered"),
	})
}

func (h *AuthHandler) Login(c *gin.Context) {
	lang := middleware.GetLang(c)
	var req model.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, model.APIResponse{
			Code:    400,
			Message: i18n.T(lang, "error.invalid_input"),
		})
		return
	}

	token, user, err := h.authSvc.Login(c.Request.Context(), &req)
	if err != nil {
		msg := i18n.T(lang, "error.invalid_credentials")
		c.JSON(http.StatusUnauthorized, model.APIResponse{Code: 401, Message: msg})
		return
	}

	c.JSON(http.StatusOK, model.APIResponse{
		Code:    200,
		Message: i18n.T(lang, "success.login"),
		Data: gin.H{
			"token": token,
			"user":  user,
		},
	})
}

func (h *AuthHandler) ForgotPassword(c *gin.Context) {
	lang := middleware.GetLang(c)
	var req model.ForgotPasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, model.APIResponse{
			Code:    400,
			Message: i18n.T(lang, "error.invalid_input"),
		})
		return
	}

	h.authSvc.ForgotPassword(c.Request.Context(), req.Email, lang)
	c.JSON(http.StatusOK, model.APIResponse{
		Code:    200,
		Message: i18n.T(lang, "success.code_sent"),
	})
}

func (h *AuthHandler) ResetPassword(c *gin.Context) {
	lang := middleware.GetLang(c)
	var req model.ResetPasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, model.APIResponse{
			Code:    400,
			Message: i18n.T(lang, "error.invalid_input"),
		})
		return
	}

	if err := h.authSvc.ResetPassword(c.Request.Context(), &req); err != nil {
		msg := i18n.T(lang, "error.server_error")
		switch err.Error() {
		case "code_expired":
			msg = i18n.T(lang, "error.code_expired")
		case "code_invalid":
			msg = i18n.T(lang, "error.code_invalid")
		}
		c.JSON(http.StatusBadRequest, model.APIResponse{Code: 400, Message: msg})
		return
	}

	c.JSON(http.StatusOK, model.APIResponse{
		Code:    200,
		Message: i18n.T(lang, "success.password_reset"),
	})
}
