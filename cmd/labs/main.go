package main

import (
	"fmt"
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"github.com/okanay/yup-backend/internal/api"
)

func main() {
	// -------------------------------------------------------------------------
	// 1. ENVIRONMENT VARIABLES - .env dosyasını yükle
	// -------------------------------------------------------------------------
	// godotenv.Load() başarısız olursa sistem environment variable'ları kullanılır.
	// Bu durum production ortamında normaldir (Docker, Kubernetes vb.)
	if err := godotenv.Load(); err != nil {
		log.Println("[MAIN::ENV] :: .env file not found, system environment variables will be used.")
	}

	// -------------------------------------------------------------------------
	// 2. GIN ROUTER SETUP - HTTP Router konfigürasyonu
	// -------------------------------------------------------------------------
	// gin.Default() Logger ve Recovery middleware'lerini otomatik ekler.
	// - Logger: Her request'i loglar
	// - Recovery: Panic'leri yakalar ve 500 döner
	router := gin.Default()

	// -------------------------------------------------------------------------
	// 4.1 MIDDLEWARE CONFIGURATION
	// -------------------------------------------------------------------------
	// CORS middleware - Cross-Origin Resource Sharing ayarları
	// Frontend'in farklı bir domain'den API'ye erişmesine izin verir.
	router.Use(api.CorsConfig())

	// Security middleware - Güvenlik header'larını ekler
	// (X-Content-Type-Options, X-Frame-Options, vb.)
	router.Use(api.SecureConfig)

	// NOT :: IP takibi yaparken CF-Connecting-IP kullanacağız.
	// >>> Bu Nginx katmanında çalışan projeler için bir güvenlik katmanı.
	// X-Forwarded-For header'ı sadece bu IP'lerden geldiğinde güvenilir kabul edilir.
	// VPS'te Nginx ile sarmalanan bir projede LocalHost değerleri eklememiz gerekiyor.
	router.SetTrustedProxies([]string{"127.0.0.1", "::1"})

	// -------------------------------------------------------------------------
	// 3. ROUTES - API endpoint tanımlamaları
	// -------------------------------------------------------------------------
	// Health check / root endpoint
	// API'nin çalışır durumda olduğunu doğrulamak için kullanılır.

	router.GET("/", func(c *gin.Context) {

		c.JSON(200, gin.H{
			"message": "Go Template API is running!",
			"env":     os.Getenv("MAIN_CONN_STRING"),
		})
	})

	// -------------------------------------------------------------------------
	// 4. SERVER START - HTTP sunucusunu başlat
	// -------------------------------------------------------------------------
	// Port belirleme - önce environment variable, yoksa default 8080
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
		log.Println("[MAIN::INFO] :: PORT environment variable not set, using default 8080.")
	}

	// Server adresi formatlanır (örn: ":8080")
	serverAddr := fmt.Sprintf(":%s", port)

	// Sunucu başlatılır - bu satır blocking'dir.
	// Hata durumunda uygulama tamamen durur.
	if err := router.Run(serverAddr); err != nil {
		log.Fatalf("[MAIN::ERROR] :: Failed to start server: %v", err)
	}
}

// DBRepository kumandamızın kabul edeceği beceri
type DBRepository interface {
	GetVersion() string
}

type CreateProductRequest struct {
	Name  string  `json:"name" form:"name" validate:"required,min=2,max=100"`
	Price float64 `json:"price" form:"price" validate:"gte=20"`
}
