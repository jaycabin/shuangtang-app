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

type AlarmHandler struct {
	coupleRepo *repository.CoupleRepo
}

func NewAlarmHandler(coupleRepo *repository.CoupleRepo) *AlarmHandler {
	return &AlarmHandler{coupleRepo: coupleRepo}
}

func (h *AlarmHandler) Create(c *gin.Context) {
	lang := middleware.GetLang(c)
	userID := middleware.GetUserID(c)

	couple, err := h.coupleRepo.FindByUserID(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusNotFound, model.APIResponse{Code: 404, Message: i18n.T(lang, "error.no_couple")})
		return
	}

	var req model.CreateAlarmRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, model.APIResponse{Code: 400, Message: i18n.T(lang, "error.invalid_input")})
		return
	}

	alarmTime, err := time.Parse(time.RFC3339, req.AlarmTime)
	if err != nil {
		c.JSON(http.StatusBadRequest, model.APIResponse{Code: 400, Message: i18n.T(lang, "error.invalid_input")})
		return
	}

	if req.TaskType == "" {
		req.TaskType = "record"
	}

	alarm := &model.Alarm{
		ID:              uuid.New(),
		CoupleID:        couple.ID,
		SetterID:        userID,
		AlarmTime:       alarmTime,
		TaskType:        req.TaskType,
		TaskDescription: req.TaskDescription,
		Status:          "pending",
	}

	c.JSON(http.StatusOK, model.APIResponse{
		Code:    200,
		Message: i18n.T(lang, "success.ok"),
		Data:    alarm,
	})
}
