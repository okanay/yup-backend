package main

import (
	"fmt"
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"github.com/okanay/yup-backend/internal/httpapi"
)

func main() {
	// -------------------------------------------------------------------------
	// 1. ENVIRONMENT VARIABLES - .env dosyasını yükle
	// -------------------------------------------------------------------------
	if err := godotenv.Load(); err != nil {
		log.Println("[MAIN::ENV] :: .env file not found, system environment variables will be used.")
	}

	// -------------------------------------------------------------------------
	// 2. GIN ROUTER SETUP - HTTP Router konfigürasyonu
	// -------------------------------------------------------------------------
	router := gin.Default()

	router.Use(httpapi.CorsConfig())
	router.Use(httpapi.SecureConfig)
	router.SetTrustedProxies([]string{"127.0.0.1", "::1"})

	router.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"message": "Go Template API is running!",
		})
	})

	// -------------------------------------------------------------------------
	// 3. SERVER START - HTTP sunucusunu başlat
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
