package main

import (
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"

	"github.com/okanay/yup-backend/internal/domain/auth"
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
	_ = auth.NewService(authRepo)

}
