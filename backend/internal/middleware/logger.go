package middleware

import (
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/rs/zerolog"
)

func Logger(logger zerolog.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		requestID := uuid.New().String()

		c.Set("request_id", requestID)
		c.Header("X-Request-ID", requestID)

		path := c.Request.URL.Path
		query := c.Request.URL.RawQuery

		c.Next()

		latency := time.Since(start)
		status := c.Writer.Status()
		clientIP := c.ClientIP()
		method := c.Request.Method

		logEvent := logger.Info()
		if status >= 400 {
			logEvent = logger.Error()
		}

		logEvent.
			Str("request_id", requestID).
			Str("method", method).
			Str("path", path).
			Str("query", query).
			Int("status", status).
			Str("ip", clientIP).
			Dur("latency", latency).
			Msg("request completed")
	}
}

func GetRequestID(c *gin.Context) string {
	id, _ := c.Get("request_id")
	return id.(string)
}
