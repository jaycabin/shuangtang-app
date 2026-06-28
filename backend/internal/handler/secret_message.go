package handler

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/base64"
	"io"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/shuangtang-app/backend/internal/i18n"
	"github.com/shuangtang-app/backend/internal/middleware"
	"github.com/shuangtang-app/backend/internal/model"
	"github.com/shuangtang-app/backend/internal/repository"
)

type SecretMessageHandler struct {
	repo       *repository.SecretMessageRepo
	coupleRepo *repository.CoupleRepo
	secretKey  []byte
}

func NewSecretMessageHandler(repo *repository.SecretMessageRepo, coupleRepo *repository.CoupleRepo, jwtSecret string) *SecretMessageHandler {
	return &SecretMessageHandler{
		repo:       repo,
		coupleRepo: coupleRepo,
		secretKey:  deriveKey(jwtSecret),
	}
}

func deriveKey(secret string) []byte {
	data := []byte(secret)
	if len(data) < 32 {
		padded := make([]byte, 32)
		copy(padded, data)
		return padded
	}
	return data[:32]
}

func encrypt(plaintext []byte, key []byte) (string, error) {
	block, err := aes.NewCipher(key)
	if err != nil {
		return "", err
	}
	aesGCM, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}
	nonce := make([]byte, aesGCM.NonceSize())
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return "", err
	}
	ciphertext := aesGCM.Seal(nonce, nonce, plaintext, nil)
	return base64.StdEncoding.EncodeToString(ciphertext), nil
}

func decrypt(ciphertext string, key []byte) (string, error) {
	data, err := base64.StdEncoding.DecodeString(ciphertext)
	if err != nil {
		return "", err
	}
	block, err := aes.NewCipher(key)
	if err != nil {
		return "", err
	}
	aesGCM, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}
	nonceSize := aesGCM.NonceSize()
	nonce, ct := data[:nonceSize], data[nonceSize:]
	plaintext, err := aesGCM.Open(nil, nonce, ct, nil)
	if err != nil {
		return "", err
	}
	return string(plaintext), nil
}

func (h *SecretMessageHandler) Send(c *gin.Context) {
	lang := middleware.GetLang(c)
	userID := middleware.GetUserID(c)

	couple, err := h.coupleRepo.FindByUserID(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusNotFound, model.APIResponse{Code: 404, Message: i18n.T(lang, "error.no_couple")})
		return
	}

	var req model.SendSecretMessageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, model.APIResponse{Code: 400, Message: i18n.T(lang, "error.invalid_input")})
		return
	}

	encrypted, err := encrypt([]byte(req.Content), h.secretKey)
	if err != nil {
		c.JSON(http.StatusInternalServerError, model.APIResponse{Code: 500, Message: i18n.T(lang, "error.server_error")})
		return
	}

	msg := &model.SecretMessage{
		ID:               uuid.New(),
		CoupleID:         couple.ID,
		SenderID:         userID,
		Content:          encrypted,
		EncryptedContent: encrypted,
	}

	if err := h.repo.Create(c.Request.Context(), msg); err != nil {
		c.JSON(http.StatusInternalServerError, model.APIResponse{Code: 500, Message: i18n.T(lang, "error.server_error")})
		return
	}

	c.JSON(http.StatusOK, model.APIResponse{
		Code:    200,
		Message: i18n.T(lang, "success.secret_sent"),
		Data:    msg,
	})
}

func (h *SecretMessageHandler) List(c *gin.Context) {
	lang := middleware.GetLang(c)
	userID := middleware.GetUserID(c)

	couple, err := h.coupleRepo.FindByUserID(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusNotFound, model.APIResponse{Code: 404, Message: i18n.T(lang, "error.no_couple")})
		return
	}

	messages, err := h.repo.ListByCouple(c.Request.Context(), couple.ID, 50, 0)
	if err != nil {
		c.JSON(http.StatusInternalServerError, model.APIResponse{Code: 500, Message: i18n.T(lang, "error.server_error")})
		return
	}

	for i := range messages {
		if messages[i].SenderID == userID {
			messages[i].Content, _ = decrypt(messages[i].EncryptedContent, h.secretKey)
		} else {
			messages[i].Content = ""
		}
	}

	c.JSON(http.StatusOK, model.APIResponse{Code: 200, Message: i18n.T(lang, "success.ok"), Data: messages})
}

func (h *SecretMessageHandler) Read(c *gin.Context) {
	lang := middleware.GetLang(c)
	_ = middleware.GetUserID(c)

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, model.APIResponse{Code: 400, Message: i18n.T(lang, "error.invalid_input")})
		return
	}

	if err := h.repo.MarkAsRead(c.Request.Context(), id); err != nil {
		c.JSON(http.StatusInternalServerError, model.APIResponse{Code: 500, Message: i18n.T(lang, "error.server_error")})
		return
	}

	c.JSON(http.StatusOK, model.APIResponse{
		Code:    200,
		Message: i18n.T(lang, "success.secret_read"),
	})
}
