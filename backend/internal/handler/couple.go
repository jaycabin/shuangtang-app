package handler

import (
	"math/rand"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shuangtang-app/backend/internal/i18n"
	"github.com/shuangtang-app/backend/internal/middleware"
	"github.com/shuangtang-app/backend/internal/model"
	"github.com/shuangtang-app/backend/internal/repository"
)

type CoupleHandler struct {
	coupleRepo *repository.CoupleRepo
	userRepo   *repository.UserRepo
}

func NewCoupleHandler(coupleRepo *repository.CoupleRepo, userRepo *repository.UserRepo) *CoupleHandler {
	return &CoupleHandler{coupleRepo: coupleRepo, userRepo: userRepo}
}

func generateInvitationCode() string {
	const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	code := make([]byte, 8)
	for i := range code {
		code[i] = chars[rand.Intn(len(chars))]
	}
	return string(code)
}

func (h *CoupleHandler) GetInfo(c *gin.Context) {
	lang := middleware.GetLang(c)
	userID := middleware.GetUserID(c)

	couple, err := h.coupleRepo.FindByUserID(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusNotFound, model.APIResponse{
			Code:    404,
			Message: i18n.T(lang, "error.no_couple"),
		})
		return
	}

	partnerID, _ := h.coupleRepo.GetPartnerID(c.Request.Context(), couple.ID, userID)
	partner, _ := h.userRepo.FindByID(c.Request.Context(), partnerID)

	c.JSON(http.StatusOK, model.APIResponse{
		Code:    200,
		Message: i18n.T(lang, "success.ok"),
		Data: gin.H{
			"couple":       couple,
			"partner":      partner,
			"invitation_code": couple.InvitationCode,
		},
	})
}

func (h *CoupleHandler) Create(c *gin.Context) {
	lang := middleware.GetLang(c)
	userID := middleware.GetUserID(c)

	var req model.CreateCoupleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, model.APIResponse{
			Code: 400, Message: i18n.T(lang, "error.invalid_input"),
		})
		return
	}

	couple := &model.Couple{
		ID:             uuid.New(),
		User1ID:        userID,
		InvitationCode: generateInvitationCode(),
		Status:         "pending",
	}

	if err := h.coupleRepo.Create(c.Request.Context(), couple); err != nil {
		c.JSON(http.StatusInternalServerError, model.APIResponse{
			Code: 500, Message: i18n.T(lang, "error.server_error"),
		})
		return
	}

	c.JSON(http.StatusOK, model.APIResponse{
		Code:    200,
		Message: i18n.T(lang, "success.couple_created"),
		Data:    couple,
	})
}

func (h *CoupleHandler) Join(c *gin.Context) {
	lang := middleware.GetLang(c)
	userID := middleware.GetUserID(c)

	var req model.JoinCoupleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, model.APIResponse{
			Code: 400, Message: i18n.T(lang, "error.invalid_input"),
		})
		return
	}

	couple, err := h.coupleRepo.FindByInvitationCode(c.Request.Context(), req.InvitationCode)
	if err != nil {
		c.JSON(http.StatusNotFound, model.APIResponse{
			Code: 404, Message: i18n.T(lang, "error.invalid_code"),
		})
		return
	}

	if couple.Status != "pending" {
		c.JSON(http.StatusBadRequest, model.APIResponse{
			Code: 400, Message: i18n.T(lang, "error.couple_already_active"),
		})
		return
	}

	if err := h.coupleRepo.Join(c.Request.Context(), couple.ID, userID); err != nil {
		c.JSON(http.StatusInternalServerError, model.APIResponse{
			Code: 500, Message: i18n.T(lang, "error.server_error"),
		})
		return
	}

	c.JSON(http.StatusOK, model.APIResponse{
		Code:    200,
		Message: i18n.T(lang, "success.couple_joined"),
	})
}
