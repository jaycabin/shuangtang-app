package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shuangtang-app/backend/internal/i18n"
	"github.com/shuangtang-app/backend/internal/middleware"
	"github.com/shuangtang-app/backend/internal/model"
	"github.com/shuangtang-app/backend/internal/repository"
)

type AlbumHandler struct {
	repo       *repository.AlbumRepo
	coupleRepo *repository.CoupleRepo
}

func NewAlbumHandler(repo *repository.AlbumRepo, coupleRepo *repository.CoupleRepo) *AlbumHandler {
	return &AlbumHandler{repo: repo, coupleRepo: coupleRepo}
}

func (h *AlbumHandler) Upload(c *gin.Context) {
	lang := middleware.GetLang(c)
	userID := middleware.GetUserID(c)

	couple, err := h.coupleRepo.FindByUserID(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusNotFound, model.APIResponse{Code: 404, Message: i18n.T(lang, "error.no_couple")})
		return
	}

	file, err := c.FormFile("image")
	if err != nil {
		c.JSON(http.StatusBadRequest, model.APIResponse{Code: 400, Message: i18n.T(lang, "error.invalid_input")})
		return
	}

	// Save file to local storage or MinIO
	imageURL := "/uploads/" + uuid.New().String() + "_" + file.Filename
	savePath := "." + imageURL
	if err := c.SaveUploadedFile(file, savePath); err != nil {
		c.JSON(http.StatusInternalServerError, model.APIResponse{Code: 500, Message: i18n.T(lang, "error.server_error")})
		return
	}

	album := &model.Album{
		ID:         uuid.New(),
		CoupleID:   couple.ID,
		UploaderID: userID,
		ImageURL:   imageURL,
	}

	if err := h.repo.Create(c.Request.Context(), album); err != nil {
		c.JSON(http.StatusInternalServerError, model.APIResponse{Code: 500, Message: i18n.T(lang, "error.server_error")})
		return
	}

	c.JSON(http.StatusOK, model.APIResponse{
		Code:    200,
		Message: i18n.T(lang, "success.album_uploaded"),
		Data:    album,
	})
}

func (h *AlbumHandler) List(c *gin.Context) {
	lang := middleware.GetLang(c)
	userID := middleware.GetUserID(c)

	couple, err := h.coupleRepo.FindByUserID(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusNotFound, model.APIResponse{Code: 404, Message: i18n.T(lang, "error.no_couple")})
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	size, _ := strconv.Atoi(c.DefaultQuery("size", "50"))
	offset := (page - 1) * size

	albums, err := h.repo.ListByCouple(c.Request.Context(), couple.ID, size, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, model.APIResponse{Code: 500, Message: i18n.T(lang, "error.server_error")})
		return
	}

	c.JSON(http.StatusOK, model.APIResponse{Code: 200, Message: i18n.T(lang, "success.ok"), Data: albums})
}
