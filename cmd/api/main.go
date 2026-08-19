package main

import (
	"log/slog"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"

	"github.com/okanay/yup-backend/internal/core"
	"github.com/okanay/yup-backend/internal/domain/auth"
	"github.com/okanay/yup-backend/internal/middleware"
	"github.com/okanay/yup-backend/internal/platform/postgres"
)

func main() {
	// -------------------------------------------------------------------------
	// 1. LOGGER SETUP
	// -------------------------------------------------------------------------
	slogLogger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	slog.SetDefault(slogLogger)

	// -------------------------------------------------------------------------
	// 2. ENVIRONMENT VARIABLES
	// -------------------------------------------------------------------------
	if err := godotenv.Load(".env"); err != nil {
		slog.Warn("godotenv file not found, system environment variables will be used.")
	}

	// -------------------------------------------------------------------------
	// 3. DATABASE CONNECTION - PostgreSQL bağlantısı
	// -------------------------------------------------------------------------
	db, err := postgres.Initialize()
	if err != nil {
		slog.Error("Failed to connect to database", "error", err)
	}

	defer db.Close()
	slog.Info("Successfully connected to the database.")

	// -------------------------------------------------------------------------
	// 4. GIN ROUTER SETUP - HTTP Router konfigürasyonu
	// -------------------------------------------------------------------------
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

	router.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"message": "Go Template API is running!",
			"ip":      c.ClientIP(),
		})
	})

	// -------------------------------------------------------------------------
	// 5. SERVER START
	// -------------------------------------------------------------------------
	port := core.GetEnvString("PORT", "8080")
	slog.Info("server starting", "port", port)

	if err := router.Run(":" + port); err != nil {
		slog.Error("failed to start server", "error", err)
		os.Exit(1)
	}
}
