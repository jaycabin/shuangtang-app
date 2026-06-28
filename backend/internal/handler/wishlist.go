package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shuangtang-app/backend/internal/i18n"
	"github.com/shuangtang-app/backend/internal/middleware"
	"github.com/shuangtang-app/backend/internal/model"
	"github.com/shuangtang-app/backend/internal/repository"
)

type WishlistHandler struct {
	repo       *repository.WishlistRepo
	coupleRepo *repository.CoupleRepo
}

func NewWishlistHandler(repo *repository.WishlistRepo, coupleRepo *repository.CoupleRepo) *WishlistHandler {
	return &WishlistHandler{repo: repo, coupleRepo: coupleRepo}
}

func (h *WishlistHandler) Create(c *gin.Context) {
	lang := middleware.GetLang(c)
	userID := middleware.GetUserID(c)

	couple, err := h.coupleRepo.FindByUserID(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusNotFound, model.APIResponse{Code: 404, Message: i18n.T(lang, "error.no_couple")})
		return
	}

	var req model.CreateWishlistRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, model.APIResponse{Code: 400, Message: i18n.T(lang, "error.invalid_input")})
		return
	}

	item := &model.WishlistItem{
		ID:          uuid.New(),
		CoupleID:    couple.ID,
		CreatorID:   userID,
		Title:       req.Title,
		Description: req.Description,
		ImageURL:    req.ImageURL,
		Price:       req.Price,
	}

	if err := h.repo.Create(c.Request.Context(), item); err != nil {
		c.JSON(http.StatusInternalServerError, model.APIResponse{Code: 500, Message: i18n.T(lang, "error.server_error")})
		return
	}

	c.JSON(http.StatusOK, model.APIResponse{Code: 200, Message: i18n.T(lang, "success.ok"), Data: item})
}

func (h *WishlistHandler) List(c *gin.Context) {
	lang := middleware.GetLang(c)
	userID := middleware.GetUserID(c)

	couple, err := h.coupleRepo.FindByUserID(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusNotFound, model.APIResponse{Code: 404, Message: i18n.T(lang, "error.no_couple")})
		return
	}

	items, err := h.repo.ListByCouple(c.Request.Context(), couple.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, model.APIResponse{Code: 500, Message: i18n.T(lang, "error.server_error")})
		return
	}

	c.JSON(http.StatusOK, model.APIResponse{Code: 200, Message: i18n.T(lang, "success.ok"), Data: items})
}

func (h *WishlistHandler) Claim(c *gin.Context) {
	lang := middleware.GetLang(c)
	userID := middleware.GetUserID(c)

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, model.APIResponse{Code: 400, Message: i18n.T(lang, "error.invalid_input")})
		return
	}

	if err := h.repo.Claim(c.Request.Context(), id, userID); err != nil {
		c.JSON(http.StatusInternalServerError, model.APIResponse{Code: 500, Message: i18n.T(lang, "error.server_error")})
		return
	}

	c.JSON(http.StatusOK, model.APIResponse{Code: 200, Message: i18n.T(lang, "success.ok")})
}

func (h *WishlistHandler) Complete(c *gin.Context) {
	lang := middleware.GetLang(c)

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, model.APIResponse{Code: 400, Message: i18n.T(lang, "error.invalid_input")})
		return
	}

	if err := h.repo.Complete(c.Request.Context(), id); err != nil {
		c.JSON(http.StatusInternalServerError, model.APIResponse{Code: 500, Message: i18n.T(lang, "error.server_error")})
		return
	}

	c.JSON(http.StatusOK, model.APIResponse{Code: 200, Message: i18n.T(lang, "success.ok")})
}
