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

type CheckInHandler struct {
	repo       *repository.CheckInRepo
	coupleRepo *repository.CoupleRepo
}

func NewCheckInHandler(repo *repository.CheckInRepo, coupleRepo *repository.CoupleRepo) *CheckInHandler {
	return &CheckInHandler{repo: repo, coupleRepo: coupleRepo}
}

func (h *CheckInHandler) ListTasks(c *gin.Context) {
	lang := middleware.GetLang(c)
	userID := middleware.GetUserID(c)

	couple, err := h.coupleRepo.FindByUserID(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusNotFound, model.APIResponse{Code: 404, Message: i18n.T(lang, "error.no_couple")})
		return
	}

	tasks, err := h.repo.ListTasks(c.Request.Context(), couple.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, model.APIResponse{Code: 500, Message: i18n.T(lang, "error.server_error")})
		return
	}

	c.JSON(http.StatusOK, model.APIResponse{Code: 200, Message: i18n.T(lang, "success.ok"), Data: tasks})
}

func (h *CheckInHandler) DoCheckIn(c *gin.Context) {
	lang := middleware.GetLang(c)
	userID := middleware.GetUserID(c)

	taskIDStr := c.Param("task_id")
	taskID, err := uuid.Parse(taskIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, model.APIResponse{Code: 400, Message: i18n.T(lang, "error.invalid_input")})
		return
	}

	record := &model.CheckInRecord{
		ID:        uuid.New(),
		TaskID:    taskID,
		UserID:    userID,
		CheckDate: time.Now().Truncate(24 * time.Hour),
	}

	if err := h.repo.CreateRecord(c.Request.Context(), record); err != nil {
		c.JSON(http.StatusInternalServerError, model.APIResponse{Code: 500, Message: i18n.T(lang, "error.server_error")})
		return
	}

	c.JSON(http.StatusOK, model.APIResponse{Code: 200, Message: i18n.T(lang, "success.checkin_done"), Data: record})
}
