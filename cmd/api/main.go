package main

import (
	"log/slog"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"

	"github.com/okanay/yup-backend/internal/core"
	"github.com/okanay/yup-backend/internal/domain/auth"
	"github.com/okanay/yup-backend/internal/middleware"
	"github.com/okanay/yup-backend/internal/platform/postgres"
)

func main() {
	// 0. Logger Setup
	slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stdout, nil)))

	// 1. Configuration & Environment
	config := core.LoadConfig()

	// 2. Healthcheck Probe
	core.HealthCheckProbe(config.Port, config.HealthPath)

	// 3. Database Connection
	db, err := postgres.Initialize(config.Postgres)
	if err != nil {
		slog.Error("Failed to connect to database", "error", err)
		os.Exit(1)
	}

	defer db.Close()
	slog.Info("Successfully connected to the database.")

	// 4. Gin Router Setup
	authRepo := auth.NewRepository(db)
	_ = auth.NewService(authRepo)

	router := gin.New()
	router.TrustedPlatform = gin.PlatformCloudflare
	router.SetTrustedProxies([]string{"127.0.0.1", "::1"})

	router.Use(
		gin.Recovery(),
		middleware.CorsMiddleware(),
		middleware.SecureMiddleware(),
		middleware.LoggerMiddleware(),
	)

	router.GET(config.HealthPath, func(c *gin.Context) {
		if err := db.Ping(); err != nil {
			core.ErrorResponse(c, err, http.StatusServiceUnavailable, "health_error", "down")
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"message": "API is running!",
			"ip":      c.ClientIP(),
		})
	})

	// 5. Server Start
	slog.Info("server starting", "port", config.Port)
	if err := router.Run(":" + config.Port); err != nil {
		slog.Error("failed to start server", "error", err)
		os.Exit(1)
	}
}
