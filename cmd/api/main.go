package main

import (
	"fmt"
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"

	"github.com/okanay/yup-backend/internal/auth"
	"github.com/okanay/yup-backend/internal/httpapi"
	"github.com/okanay/yup-backend/internal/httpapi/middleware"
	"github.com/okanay/yup-backend/internal/platform/postgres"
	"github.com/okanay/yup-backend/internal/platform/redis"
)

func main() {
	// -------------------------------------------------------------------------
	// 1. ENVIRONMENT VARIABLES - .env dosyasını yükle
	// -------------------------------------------------------------------------
	if err := godotenv.Load(); err != nil {
		log.Println("[MAIN::ENV] :: .env file not found, system environment variables will be used.")
	}

	// -------------------------------------------------------------------------
	// 2. DATABASE CONNECTION - PostgreSQL bağlantısı
	// -------------------------------------------------------------------------
	db, err := postgres.Initialize(os.Getenv("DB_MAIN_CONN_STRING"))
	if err != nil {
		log.Fatalf("[DB::ERROR] :: Failed to connect to database: %v", err)
	}

	defer db.Close()
	log.Println("[DB::SUCCESS] :: Successfully connected to the database.")

	// -------------------------------------------------------------------------
	// 3. REDIS CONNECTION - Redis bağlantısı ve konfigürasyonu
	// -------------------------------------------------------------------------
	redisAddr := os.Getenv("REDIS_ADDR")
	redisUsername := os.Getenv("REDIS_USERNAME")
	redisPass := os.Getenv("REDIS_PASS")
	redisDB := os.Getenv("REDIS_DB")

	redisClient, err := redis.Initialize(
		[]string{redisAddr},
		redisUsername,
		redisPass,
		redisDB,
	)

	if err != nil {
		log.Fatalf("[REDIS::ERROR] :: Redis connection failed: %v", err)
	}

	if gin.Mode() == gin.DebugMode {
		log.Println("[REDIS::INFO] :: DEV MODE: Clearing Redis cache...")

		if err := redisClient.ClearAll(); err != nil {
			log.Printf("[REDIS::ERROR] :: Error clearing cache: %v", err)
		} else {
			log.Println("[REDIS::SUCCESS] :: DEV MODE: Redis cache cleared successfully.")
		}
	}

	log.Println("[REDIS::SUCCESS] :: Redis connection successful.")

	// -------------------------------------------------------------------------
	// 4. GIN ROUTER SETUP - HTTP Router konfigürasyonu
	// -------------------------------------------------------------------------
	authRepo := auth.NewRepository(db)
	authService := auth.NewService(authRepo)

	router := gin.Default()
	router.SetTrustedProxies([]string{"127.0.0.1", "::1"})

	router.Use(httpapi.CorsConfig())
	router.Use(httpapi.SecureConfig)

	router.Use(middleware.AuthMiddleware(authService))
	router.Use(middleware.LoggerMiddleware())
	router.Use(middleware.RateLimitMiddleware())
	router.Use(middleware.RequirePermission())

	// -------------------------------------------------------------------------
	// 5. ROUTES - API endpoint tanımlamaları
	// -------------------------------------------------------------------------
	router.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"message": "Go Template API is running!",
		})
	})

	// -------------------------------------------------------------------------
	// 6. SERVER START - HTTP sunucusunu başlat
	// -------------------------------------------------------------------------
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
		log.Println("[MAIN::INFO] :: PORT environment variable not set, using default 8080.")
	}

	serverAddr := fmt.Sprintf(":%s", port)

	if err := router.Run(serverAddr); err != nil {
		log.Fatalf("[MAIN::ERROR] :: Failed to start server: %v", err)
	}
}
