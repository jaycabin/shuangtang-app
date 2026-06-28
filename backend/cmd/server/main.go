package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"path/filepath"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
	"github.com/rs/zerolog"
	"github.com/shuangtang-app/backend/internal/config"
	"github.com/shuangtang-app/backend/internal/handler"
	"github.com/shuangtang-app/backend/internal/i18n"
	"github.com/shuangtang-app/backend/internal/middleware"
	"github.com/shuangtang-app/backend/internal/repository"
	"github.com/shuangtang-app/backend/internal/service"
	"github.com/shuangtang-app/backend/internal/ws"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		panic(fmt.Sprintf("Failed to load config: %v", err))
	}

	logger := zerolog.New(os.Stderr).With().Timestamp().Logger().Level(cfg.Logger())

	localesDir := filepath.Join(".", "locales")
	if err := i18n.Init(localesDir, cfg.I18n.DefaultLang); err != nil {
		logger.Warn().Err(err).Msg("Failed to load locales, using defaults")
	}

	dbPool, err := repository.NewDBPool(cfg.DB.DSN())
	if err != nil {
		logger.Fatal().Err(err).Msg("Failed to connect to database")
	}
	defer dbPool.Close()
	logger.Info().Msg("Database connected")

	rdb := redis.NewClient(&redis.Options{
		Addr:     cfg.Redis.Addr(),
		Password: cfg.Redis.Password,
		DB:       cfg.Redis.DB,
	})
	if err := rdb.Ping(context.Background()).Err(); err != nil {
		logger.Warn().Err(err).Msg("Redis not available, running without cache/real-time features")
		rdb = nil
	} else {
		logger.Info().Msg("Redis connected")
	}

	userRepo := repository.NewUserRepo(dbPool)
	coupleRepo := repository.NewCoupleRepo(dbPool)
	momentRepo := repository.NewMomentRepo(dbPool)
	anniversaryRepo := repository.NewAnniversaryRepo(dbPool)
	checkInRepo := repository.NewCheckInRepo(dbPool)
	wishlistRepo := repository.NewWishlistRepo(dbPool)
	albumRepo := repository.NewAlbumRepo(dbPool)
	secretMsgRepo := repository.NewSecretMessageRepo(dbPool)
	systemCfgRepo := repository.NewSystemConfigRepo(dbPool)

	emailSvc := service.NewEmailService(&cfg.SMTP)
	authSvc := service.NewAuthService(userRepo, coupleRepo, rdb, &cfg.JWT, emailSvc)

	authH := handler.NewAuthHandler(authSvc)
	coupleH := handler.NewCoupleHandler(coupleRepo, userRepo)
	timelineH := handler.NewTimelineHandler(momentRepo, coupleRepo, anniversaryRepo)
	anniversaryH := handler.NewAnniversaryHandler(anniversaryRepo, coupleRepo)
	checkInH := handler.NewCheckInHandler(checkInRepo, coupleRepo)
	wishlistH := handler.NewWishlistHandler(wishlistRepo, coupleRepo)
	secretMsgH := handler.NewSecretMessageHandler(secretMsgRepo, coupleRepo, cfg.JWT.Secret)
	albumH := handler.NewAlbumHandler(albumRepo, coupleRepo)
	alarmH := handler.NewAlarmHandler(coupleRepo)
	adminH := handler.NewAdminHandler(&cfg.Admin, systemCfgRepo)

	wsHub := ws.NewHub(rdb)

	ginMode := cfg.Server.Mode
	if ginMode == "release" {
		gin.SetMode(gin.ReleaseMode)
	}
	r := gin.New()
	r.Use(middleware.CORS(cfg.Server.AllowedOrigins))
	r.Use(middleware.Logger(logger))
	r.Use(middleware.I18n())
	r.Use(gin.Recovery())

	r.Static("/uploads", "./uploads")

	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok", "service": "shuangtang-backend"})
	})
	r.GET("/ready", func(c *gin.Context) {
		if err := dbPool.Ping(context.Background()); err != nil {
			c.JSON(503, gin.H{"status": "not ready"})
			return
		}
		c.JSON(200, gin.H{"status": "ready"})
	})

	api := r.Group("/api/v1")
	{
		auth := api.Group("/auth")
		{
			auth.POST("/send-code", authH.SendCode)
			auth.POST("/register", authH.Register)
			auth.POST("/login", authH.Login)
			auth.POST("/forgot-password", authH.ForgotPassword)
			auth.POST("/reset-password", authH.ResetPassword)
		}

		protected := api.Group("")
		protected.Use(middleware.AuthRequired(cfg.JWT.Secret))
		{
			protected.GET("/couple/info", coupleH.GetInfo)
			protected.POST("/couple/create", coupleH.Create)
			protected.POST("/couple/join", coupleH.Join)

			protected.GET("/timeline", timelineH.GetTimeline)
			protected.POST("/moments", timelineH.CreateMoment)

			protected.GET("/anniversaries", anniversaryH.List)
			protected.POST("/anniversaries", anniversaryH.Create)

			protected.GET("/checkin/tasks", checkInH.ListTasks)
			protected.POST("/checkin/:task_id", checkInH.DoCheckIn)

			protected.GET("/wishlist", wishlistH.List)
			protected.POST("/wishlist", wishlistH.Create)
			protected.POST("/wishlist/:id/claim", wishlistH.Claim)
			protected.POST("/wishlist/:id/complete", wishlistH.Complete)

			protected.GET("/secret-messages", secretMsgH.List)
			protected.POST("/secret-messages", secretMsgH.Send)
			protected.POST("/secret-messages/:id/read", secretMsgH.Read)

			protected.GET("/albums", albumH.List)
			protected.POST("/albums/upload", albumH.Upload)

			protected.POST("/alarms", alarmH.Create)
		}
	}

	r.GET("/ws/v1/location", func(c *gin.Context) {
		token := c.Query("token")
		if token == "" {
			c.JSON(401, gin.H{"error": "unauthorized"})
			return
		}

		conn, err := ws.Upgrader.Upgrade(c.Writer, c.Request, nil)
		if err != nil {
			logger.Error().Err(err).Msg("WebSocket upgrade failed")
			return
		}

		_ = token
		client := &ws.Client{
			Conn: conn,
			Send: make(chan []byte, 256),
			Hub:  wsHub,
		}
		wsHub.Register(client)
		go client.WritePump()
		go client.ReadPump()
	})

	admin := r.Group("/admin")
	{
		admin.GET("/", adminH.LoginPage)
		admin.POST("/login", adminH.Login)
		admin.GET("/dashboard", adminH.Dashboard)
		admin.GET("/smtp", adminH.SMTPPage)
		admin.POST("/smtp/save", adminH.SaveSMTP)
		admin.POST("/smtp/test", adminH.TestSMTP)
		admin.GET("/templates", adminH.TemplatesPage)
		admin.POST("/templates/save", adminH.SaveTemplates)
		admin.GET("/settings", adminH.SettingsPage)
		admin.POST("/settings/save", adminH.SaveSettings)
		admin.POST("/logout", adminH.Logout)
	}

	srv := &http.Server{
		Addr:    fmt.Sprintf(":%s", cfg.Server.Port),
		Handler: r,
	}

	go func() {
		logger.Info().Str("port", cfg.Server.Port).Msg("Server starting")
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal().Err(err).Msg("Server failed")
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Info().Msg("Shutting down server...")
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		logger.Fatal().Err(err).Msg("Server forced to shutdown")
	}
	logger.Info().Msg("Server exited")
}
