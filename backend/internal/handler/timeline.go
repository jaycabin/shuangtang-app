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

type TimelineHandler struct {
	momentRepo      *repository.MomentRepo
	coupleRepo      *repository.CoupleRepo
	anniversaryRepo *repository.AnniversaryRepo
}

func NewTimelineHandler(momentRepo *repository.MomentRepo, coupleRepo *repository.CoupleRepo,
	anniversaryRepo *repository.AnniversaryRepo) *TimelineHandler {
	return &TimelineHandler{
		momentRepo:      momentRepo,
		coupleRepo:      coupleRepo,
		anniversaryRepo: anniversaryRepo,
	}
}

func (h *TimelineHandler) GetTimeline(c *gin.Context) {
	lang := middleware.GetLang(c)
	userID := middleware.GetUserID(c)

	couple, err := h.coupleRepo.FindByUserID(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusNotFound, model.APIResponse{
			Code: 404, Message: i18n.T(lang, "error.no_couple"),
		})
		return
	}

	cursorStr := c.DefaultQuery("cursor", "")
	var cursor time.Time
	if cursorStr != "" {
		cursor, _ = time.Parse(time.RFC3339, cursorStr)
	}
	if cursor.IsZero() {
		cursor = time.Now()
	}

	limit := 20
	moments, err := h.momentRepo.GetTimeline(c.Request.Context(), couple.ID, cursor, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, model.APIResponse{
			Code: 500, Message: i18n.T(lang, "error.server_error"),
		})
		return
	}

	// Get days since couple started
	var daysSince int64
	if couple.StartedAt != nil {
		daysSince = int64(time.Since(*couple.StartedAt).Hours() / 24)
	}

	c.JSON(http.StatusOK, model.APIResponse{
		Code:    200,
		Message: i18n.T(lang, "success.ok"),
		Data: gin.H{
			"moments":     moments,
			"days_since":  daysSince,
			"has_more":    len(moments) >= limit,
		},
	})
}

func (h *TimelineHandler) CreateMoment(c *gin.Context) {
	lang := middleware.GetLang(c)
	userID := middleware.GetUserID(c)

	couple, err := h.coupleRepo.FindByUserID(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusNotFound, model.APIResponse{
			Code: 404, Message: i18n.T(lang, "error.no_couple"),
		})
		return
	}

	var req model.CreateMomentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, model.APIResponse{
			Code: 400, Message: i18n.T(lang, "error.invalid_input"),
		})
		return
	}

	moment := &model.Moment{
		ID:        uuid.New(),
		CoupleID:  couple.ID,
		AuthorID:  userID,
		Type:      "moment",
		Content:   req.Content,
		ImageURLs: req.ImageURLs,
		Location:  req.Location,
		MoodTag:   req.MoodTag,
	}

	if err := h.momentRepo.Create(c.Request.Context(), moment); err != nil {
		c.JSON(http.StatusInternalServerError, model.APIResponse{
			Code: 500, Message: i18n.T(lang, "error.server_error"),
		})
		return
	}

	c.JSON(http.StatusOK, model.APIResponse{
		Code:    200,
		Message: i18n.T(lang, "success.moment_created"),
		Data:    moment,
	})
}
