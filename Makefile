# =============================================================================
# 1. ENVIRONMENT & CONFIGURATION
# =============================================================================
# .env dosyası varsa içe aktarır ve alt süreçlere export eder
-include .env
export

# .env içinde yoksa değişkenler tamamen boş string kalır
DB_USER ?=
DB_NAME ?=

# =============================================================================
# 2. PATHS & APPLICATION METADATA
# =============================================================================
# Klasör İsimleri
API_FOLDER_NAME     := api
MIGRATE_FOLDER_NAME := migrate

# Temel Dizinler
DIR_CMD             := ./cmd
DIR_BIN             := ./bin
DIR_TMP             := ./tmp
DIR_BACKUPS         := ./backups

# Kaynak ve Çıktı Yolları
APP_CMD_PATH        := $(DIR_CMD)/$(API_FOLDER_NAME)
APP_BIN_PATH        := $(DIR_BIN)/$(API_FOLDER_NAME)
TMP_BIN_PATH        := $(DIR_TMP)/$(API_FOLDER_NAME)
MIGRATE_CMD_PATH    := $(DIR_CMD)/$(MIGRATE_FOLDER_NAME)

# Docker Servis Adları (docker-compose.yml ile birebir eşleşir)
DOCKER_SERVICE_API  := api
DOCKER_SERVICE_DB   := postgres

# Yedekleme Dosyası Formatı
YEAR    	:= $(shell date +'%Y')
MONTH   	:= $(shell date +'%m')
DAY     	:= $(shell date +'%d')
HOUR    	:= $(shell date +'%H')
MINUTE  	:= $(shell date +'%M')
BACKUP_FILE := $(DIR_BACKUPS)/$(YEAR)-$(MONTH)-$(DAY)-$(HOUR)-$(MINUTE).sql

# =============================================================================
# 3. PHONY TARGETS
# =============================================================================
.PHONY: help dev build run clean test \
        db-up db-down db-shell db-backup \
        migrate-up migrate-down \
        up down restart logs ps update

# =============================================================================
# 4. YARDIM MENÜSÜ
# =============================================================================
help:
	@echo "Kullanılabilir Komutlar:"
	@echo "  make dev          - Yerel API'yi Air ile hot-reload modunda başlatır"
	@echo "  make build        - Go kodunu yerel binary olarak derler"
	@echo "  make run          - Yerel binary'yi derler ve çalıştırır"
	@echo "  make clean        - Derleme, geçici ve yedek dosyalarını temizler"
	@echo "  make test         - Tüm testleri race detector ile çalıştırır"
	@echo "  make db-up        - Sadece PostgreSQL konteynerini başlatır"
	@echo "  make db-down      - PostgreSQL konteynerini durdurur"
	@echo "  make db-shell     - psql terminaline bağlanır"
	@echo "  make db-backup    - Veritabanı yedeğini $(DIR_BACKUPS)/ altına kaydeder"
	@echo "  make migrate-up   - Veritabanı migration'larını çalıştırır"
	@echo "  make migrate-down - Son migration işlemini geri alır"
	@echo "  make up           - Tüm Docker stack'ini (DB + API) ayağa kaldırır"
	@echo "  make down         - Tüm Docker servislerini durdurur"
	@echo "  make restart      - Docker servislerini yeniden başlatır"
	@echo "  make logs         - Canlı API konteyner loglarını izler"
	@echo "  make ps           - Konteyner durumlarını listeler"
	@echo "  make update       - VPS Deploy: Git pull -> Migrate -> Build -> Prune"

# =============================================================================
# 5. LOCAL DEVELOPMENT (Air / Native Go)
# =============================================================================
dev:
	@echo "API modu (Hot-Reload) başlatılıyor..."
	air --build.cmd "go build -o $(TMP_BIN_PATH) $(APP_CMD_PATH)" --build.entrypoint "$(TMP_BIN_PATH)"

build:
	@mkdir -p $(DIR_BIN)
	go build -o $(APP_BIN_PATH) $(APP_CMD_PATH)
	@echo "Derlendi: $(APP_BIN_PATH)"

run: build
	@echo "Uygulama başlatılıyor..."
	$(APP_BIN_PATH)

test:
	go test -v -race ./...

clean:
	@rm -rf $(DIR_BIN) $(DIR_TMP) $(DIR_BACKUPS)
	@echo "Temizlendi: $(DIR_BIN), $(DIR_TMP), $(DIR_BACKUPS)"

# =============================================================================
# 6. DATABASE MANAGEMENT (PostgreSQL)
# =============================================================================
db-up:
	@echo "PostgreSQL başlatılıyor..."
	@docker compose up -d $(DOCKER_SERVICE_DB)

db-down:
	@echo "PostgreSQL durduruluyor..."
	@docker compose stop $(DOCKER_SERVICE_DB)

db-shell:
	@if [ -z "$(DB_USER)" ] || [ -z "$(DB_NAME)" ]; then \
		echo "Hata: .env dosyasında DB_USER veya DB_NAME tanımlı değil!"; exit 1; \
	fi
	@docker compose exec -it $(DOCKER_SERVICE_DB) psql -U $(DB_USER) -d $(DB_NAME)

db-backup:
	@if [ -z "$(DB_USER)" ] || [ -z "$(DB_NAME)" ]; then \
		echo "Hata: .env dosyasında DB_USER veya DB_NAME tanımlı değil!"; exit 1; \
	fi
	@mkdir -p $(DIR_BACKUPS)
	@docker compose exec -T $(DOCKER_SERVICE_DB) pg_dump -U $(DB_USER) $(DB_NAME) > $(BACKUP_FILE)
	@echo "Yedek alındı: $(BACKUP_FILE)"

# =============================================================================
# 7. MIGRATION OPERATIONS
# =============================================================================
migrate-up:
	@echo "Migration'lar uygulanıyor (UP)..."
	go run $(MIGRATE_CMD_PATH) up

migrate-down:
	@echo "Migration'lar geri alınıyor (DOWN)..."
	go run $(MIGRATE_CMD_PATH) down

# =============================================================================
# 8. DOCKER STACK MANAGEMENT
# =============================================================================
up:
	@echo "Tüm Docker servisleri başlatılıyor..."
	@docker compose up -d --build

down:
	@echo "Tüm Docker servisleri durduruluyor..."
	@docker compose down

restart: down up

logs:
	@docker compose logs -f $(DOCKER_SERVICE_API)

ps:
	@docker compose ps

# =============================================================================
# 9. PRODUCTION DEPLOY & VPS UPDATE
# =============================================================================
update:
	@echo "1. En güncel kodlar çekiliyor..."
	git pull origin main
	@echo "2. Veritabanı migration'ları uygulanıyor..."
	@go run $(MIGRATE_CMD_PATH) up
	@echo "3. Yeni API derlenip arka planda ayağa kaldırılıyor..."
	@docker compose up -d --build $(DOCKER_SERVICE_API)
	@echo "4. Eski imaj kalıntıları temizleniyor..."
	@docker image prune -f
	@echo "Tüm güncelleme başarıyla tamamlandı!"
