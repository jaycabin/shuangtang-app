package handler

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shuangtang-app/backend/internal/i18n"
	"github.com/shuangtang-app/backend/internal/middleware"
	"github.com/shuangtang-app/backend/internal/model"
	"github.com/shuangtang-app/backend/internal/repository"
)

type AnniversaryHandler struct {
	repo        *repository.AnniversaryRepo
	coupleRepo  *repository.CoupleRepo
}

func NewAnniversaryHandler(repo *repository.AnniversaryRepo, coupleRepo *repository.CoupleRepo) *AnniversaryHandler {
	return &AnniversaryHandler{repo: repo, coupleRepo: coupleRepo}
}

func (h *AnniversaryHandler) Create(c *gin.Context) {
	lang := middleware.GetLang(c)
	userID := middleware.GetUserID(c)

	couple, err := h.coupleRepo.FindByUserID(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusNotFound, model.APIResponse{Code: 404, Message: i18n.T(lang, "error.no_couple")})
		return
	}

	var req model.CreateAnniversaryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, model.APIResponse{Code: 400, Message: i18n.T(lang, "error.invalid_input")})
		return
	}

	date, err := time.Parse("2006-01-02", req.Date)
	if err != nil {
		c.JSON(http.StatusBadRequest, model.APIResponse{Code: 400, Message: i18n.T(lang, "error.invalid_input")})
		return
	}

	if req.RemindBefore == 0 {
		req.RemindBefore = 1
	}
	if req.Icon == "" {
		req.Icon = "❤️"
	}

	anniversary := &model.Anniversary{
		ID:           uuid.New(),
		CoupleID:     couple.ID,
		Title:        req.Title,
		Date:         date,
		IsRecurring:  req.IsRecurring,
		RemindBefore: req.RemindBefore,
		Icon:         req.Icon,
		CreatedBy:    userID,
	}

	if err := h.repo.Create(c.Request.Context(), anniversary); err != nil {
		c.JSON(http.StatusInternalServerError, model.APIResponse{Code: 500, Message: i18n.T(lang, "error.server_error")})
		return
	}

	c.JSON(http.StatusOK, model.APIResponse{Code: 200, Message: i18n.T(lang, "success.ok"), Data: anniversary})
}

func (h *AnniversaryHandler) List(c *gin.Context) {
	lang := middleware.GetLang(c)
	userID := middleware.GetUserID(c)

	couple, err := h.coupleRepo.FindByUserID(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusNotFound, model.APIResponse{Code: 404, Message: i18n.T(lang, "error.no_couple")})
		return
	}

	anniversaries, err := h.repo.ListByCouple(c.Request.Context(), couple.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, model.APIResponse{Code: 500, Message: i18n.T(lang, "error.server_error")})
		return
	}

	c.JSON(http.StatusOK, model.APIResponse{Code: 200, Message: i18n.T(lang, "success.ok"), Data: anniversaries})
}
