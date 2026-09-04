# =============================================================================
# 1. ORTAM DEĞİŞKENLERİ VE DOSYA DİZİNLERİ
# =============================================================================
-include .env
export

# SSH Yapılandırması (~/.ssh/config ile eşleşir)
SSH_HOST_PROD       := yup-root
SSH_TUNNEL_HOST     := yup-tunnel
REMOTE_PROJECT_DIR  := /home/ubuntu/yup-backend

# Proje Yolları
DIR_CMD             := ./cmd/api
DIR_BIN             := ./bin/api
DIR_TMP             := ./tmp/api
DIR_BACKUPS         := ./backups
MIGRATIONS_PATH     := $(shell pwd)/migrations

# Zaman Damgası (Örn: 2026-09-04-18-30)
TIMESTAMP           := $(shell date +'%Y-%m-%d-%H-%M-%S')

# Docker Servis ve İmaj Bilgileri
DOCKER_SERVICE_API  := api
DOCKER_SERVICE_DB   := postgres
MIGRATE_IMAGE       := migrate/migrate:v4.18.2

# Migration İsimlendirme Parametresi (n veya name kabul eder)
MIGRATE_NAME        := $(if $(n),$(n),$(name))

# DB Bağlantı Dizgileri (Docker Desktop / macOS uyumlu host.docker.internal)
LOCAL_DB_PORT       ?= 5432
LOCAL_DB_URL        := postgres://$(DB_USER):$(DB_PASSWORD)@host.docker.internal:$(LOCAL_DB_PORT)/$(DB_NAME)?sslmode=disable

PROD_TUNNEL_PORT    := 5433
PROD_DB_URL         := postgres://$(PROD_DB_USER):$(PROD_DB_PASSWORD)@host.docker.internal:$(PROD_TUNNEL_PORT)/$(PROD_DB_NAME)?sslmode=disable

# =============================================================================
# 2. PHONY HEDEFLERİ
# =============================================================================
.PHONY: help dev build run clean test \
        up down restart logs ps \
        db-up db-down db-shell db-backup db-backup-prod \
        migrate-create migrate-up migrate-down migrate-force migrate-version \
        db-tunnel migrate-up-prod migrate-down-prod migrate-force-prod migrate-version-prod \
        log-prod shell-prod db-shell-prod update

# =============================================================================
# 3. YARDIM MENÜSÜ
# =============================================================================
help:
	@echo "--- YEREL GELİŞTİRME (AIR & GO) ---"
	@echo "  make dev                 : Air ile API'yi hot-reload modunda başlatır"
	@echo "  make build               : Yerel binary derler"
	@echo "  make run                 : Yerel binary derleyip çalıştırır"
	@echo "  make test                : Tüm testleri race detector ile çalıştırır"
	@echo "  make clean               : Geçici ve derlenmiş dosyaları temizler"
	@echo ""
	@echo "--- YEREL DOCKER SERVİSLERİ ---"
	@echo "  make up                  : Tüm servisleri (API, DB, Nginx) ayağa kaldırır"
	@echo "  make down                : Tüm Docker servislerini durdurur"
	@echo "  make restart             : Servisleri yeniden başlatır"
	@echo "  make logs                : Yerel API konteyner loglarını canlı izler"
	@echo "  make ps                  : Çalışan servislerin durumunu listeler"
	@echo ""
	@echo "--- VERİTABANI YÖNETİMİ & YEDEKLER ---"
	@echo "  make db-up               : Yalnızca PostgreSQL konteynerini başlatır (Air için)"
	@echo "  make db-down             : Yalnızca PostgreSQL konteynerini durdurur"
	@echo "  make db-shell            : Yerel psql konsoluna bağlanır"
	@echo "  make db-backup           : Yerel DB yedeğini ./backups klasörüne alır"
	@echo "  make db-backup-prod      : Canlı DB yedeğini SSH ile çekip ./backups klasörüne alır"
	@echo ""
	@echo "--- YEREL MIGRATION (DOCKER IMAGE) ---"
	@echo "  make migrate-create n=x  : Yeni migration dosyası açar (.up.sql ve .down.sql)"
	@echo "  make migrate-up          : Yerel migrationları uygular"
	@echo "  make migrate-down        : Yerel son migrationı geri alır"
	@echo "  make migrate-force v=x   : Yerel dirty state durumunu temizler (Örn: v=1)"
	@echo "  make migrate-version     : Yerel DB migration versiyonunu gösterir"
	@echo ""
	@echo "--- CANLI (PROD) MIGRATION (SSH TÜNELİ) ---"
	@echo "  make db-tunnel           : Canlı DB SSH tünelini elle açar (Port: 5433)"
	@echo "  make migrate-up-prod     : SSH tüneli açar, canlıya migrate basar ve kapatır"
	@echo "  make migrate-down-prod   : SSH tüneli açar, canlıdan 1 migrate geri alır"
	@echo "  make migrate-force-prod  : Canlı DB dirty state temizler (Örn: v=1)"
	@echo "  make migrate-version-prod: Canlı DB versiyonunu okur"
	@echo ""
	@echo "--- CANLI VPS KONTROL & İZLEME (LOCAL TERMINAL) ---"
	@echo "  make log-prod            : Canlı sunucudaki API loglarını anlık izler"
	@echo "  make shell-prod          : Canlı sunucunun terminaline bağlanır"
	@echo "  make db-shell-prod       : Canlı sunucunun psql konsoluna bağlanır"
	@echo ""
	@echo "--- CI/CD & SUNUCU GÜNCELLEME (VPS TARAFINDA ÇALIŞIR) ---"
	@echo "  make update              : Git pull -> Docker pull -> Up -> Prune adımlarını çalıştırır"

# =============================================================================
# 4. YEREL GELİŞTİRME (Native Go / Air)
# =============================================================================
dev:
	@echo "Air (Hot-Reload) başlatılıyor..."
	air --build.cmd "go build -o $(DIR_TMP) $(DIR_CMD)" --build.entrypoint "$(DIR_TMP)"

build:
	@mkdir -p ./bin
	go build -o $(DIR_BIN) $(DIR_CMD)
	@echo "Derlendi: $(DIR_BIN)"

run: build
	@echo "Uygulama başlatılıyor..."
	$(DIR_BIN)

test:
	go test -v -race ./...

clean:
	@rm -rf ./bin ./tmp
	@echo "Temizlendi: bin/ ve tmp/ klasörleri silindi."

# =============================================================================
# 5. YEREL DOCKER SERVİSLERİ
# =============================================================================
up:
	docker compose up -d

down:
	docker compose down

restart: down up

logs:
	docker compose logs -f $(DOCKER_SERVICE_API)

ps:
	docker compose ps

# =============================================================================
# 6. VERİTABANI YÖNETİMİ & YEDEKLER
# =============================================================================
# Air ile çalışırken sadece veritabanını ayağa kaldırmak için:
db-up:
	@echo "PostgreSQL başlatılıyor..."
	@docker compose up -d $(DOCKER_SERVICE_DB)

db-down:
	@echo "PostgreSQL durduruluyor..."
	@docker compose stop $(DOCKER_SERVICE_DB)

db-shell:
	@docker compose exec -it $(DOCKER_SERVICE_DB) psql -U $(DB_USER) -d $(DB_NAME)

# Yerel PostgreSQL konteynerinden yedek alır
db-backup:
	@mkdir -p $(DIR_BACKUPS)
	@docker compose exec -T $(DOCKER_SERVICE_DB) pg_dump -U $(DB_USER) $(DB_NAME) > $(DIR_BACKUPS)/db-$(TIMESTAMP)-local.sql
	@echo "Yerel yedek kaydedildi: $(DIR_BACKUPS)/db-$(TIMESTAMP)-local.sql"

# Canlı PostgreSQL konteynerinden SSH ile veri akışı alıp doğrudan yereldeki backups klasörüne yazar
db-backup-prod:
	@mkdir -p $(DIR_BACKUPS)
	@echo "Canlı veritabanı yedeği SSH üzerinden çekiliyor..."
	@ssh $(SSH_HOST_PROD) "cd $(REMOTE_PROJECT_DIR) && docker compose exec -T postgres pg_dump -U \$$DB_USER \$$DB_NAME" > $(DIR_BACKUPS)/db-$(TIMESTAMP)-prod.sql
	@echo "Canlı yedek yerel klasöre kaydedildi: $(DIR_BACKUPS)/db-$(TIMESTAMP)-prod.sql"

# =============================================================================
# 7. YEREL MIGRATION (Docker Image Tabanlı)
# =============================================================================
# Örnek kullanım: make migrate-create n=create_users_table
migrate-create:
	@if [ -z "$(MIGRATE_NAME)" ]; then \
		echo "Hata: Migration ismi belirtilmedi! Örnek: make migrate-create n=create_users_table"; \
		exit 1; \
	fi
	@mkdir -p $(MIGRATIONS_PATH)
	docker run --rm -u $(shell id -u):$(shell id -g) -v $(MIGRATIONS_PATH):/migrations \
		$(MIGRATE_IMAGE) create -ext sql -dir /migrations -seq $(MIGRATE_NAME)

migrate-up:
	docker run --rm -v $(MIGRATIONS_PATH):/migrations --add-host=host.docker.internal:host-gateway \
		$(MIGRATE_IMAGE) -path=/migrations -database "$(LOCAL_DB_URL)" up

migrate-down:
	docker run --rm -v $(MIGRATIONS_PATH):/migrations --add-host=host.docker.internal:host-gateway \
		$(MIGRATE_IMAGE) -path=/migrations -database "$(LOCAL_DB_URL)" down 1

migrate-force:
	@if [ -z "$(V)" ]; then echo "Hata: Versiyon belirtilmedi. Örnek: make migrate-force v=1"; exit 1; fi
	docker run --rm -v $(MIGRATIONS_PATH):/migrations --add-host=host.docker.internal:host-gateway \
		$(MIGRATE_IMAGE) -path=/migrations -database "$(LOCAL_DB_URL)" force $(V)

migrate-version:
	docker run --rm -v $(MIGRATIONS_PATH):/migrations --add-host=host.docker.internal:host-gateway \
		$(MIGRATE_IMAGE) -path=/migrations -database "$(LOCAL_DB_URL)" version

# =============================================================================
# 8. CANLI (PROD) MIGRATION (SSH Tüneli ile Çalışır)
# =============================================================================
db-tunnel:
	@echo "Canlı DB SSH tüneli 5433 portunda açılıyor... Kapatmak için Ctrl+C"
	@ssh -N $(SSH_TUNNEL_HOST)

migrate-up-prod:
	@echo "SSH Tüneli açılıyor..."
	@ssh -f -N $(SSH_TUNNEL_HOST)
	@sleep 2
	@echo "Canlı DB migration (UP) uygulanıyor..."
	@docker run --rm -v $(MIGRATIONS_PATH):/migrations --add-host=host.docker.internal:host-gateway \
		$(MIGRATE_IMAGE) -path=/migrations -database "$(PROD_DB_URL)" up || true
	@echo "SSH Tüneli kapatılıyor..."
	@pkill -f "ssh -f -N $(SSH_TUNNEL_HOST)" || true

migrate-down-prod:
	@echo "SSH Tüneli açılıyor..."
	@ssh -f -N $(SSH_TUNNEL_HOST)
	@sleep 2
	@echo "Canlı DB migration (DOWN) geri alınıyor..."
	@docker run --rm -v $(MIGRATIONS_PATH):/migrations --add-host=host.docker.internal:host-gateway \
		$(MIGRATE_IMAGE) -path=/migrations -database "$(PROD_DB_URL)" down 1 || true
	@echo "SSH Tüneli kapatılıyor..."
	@pkill -f "ssh -f -N $(SSH_TUNNEL_HOST)" || true

migrate-force-prod:
	@if [ -z "$(V)" ]; then echo "Hata: Versiyon belirtilmedi. Örnek: make migrate-force-prod v=1"; exit 1; fi
	@echo "SSH Tüneli açılıyor..."
	@ssh -f -N $(SSH_TUNNEL_HOST)
	@sleep 2
	@echo "Canlı DB dirty state temizleniyor (v=$(V))..."
	@docker run --rm -v $(MIGRATIONS_PATH):/migrations --add-host=host.docker.internal:host-gateway \
		$(MIGRATE_IMAGE) -path=/migrations -database "$(PROD_DB_URL)" force $(V) || true
	@echo "SSH Tüneli kapatılıyor..."
	@pkill -f "ssh -f -N $(SSH_TUNNEL_HOST)" || true

migrate-version-prod:
	@echo "SSH Tüneli açılıyor..."
	@ssh -f -N $(SSH_TUNNEL_HOST)
	@sleep 2
	@echo "Canlı DB versiyonu okunuyor..."
	@docker run --rm -v $(MIGRATIONS_PATH):/migrations --add-host=host.docker.internal:host-gateway \
		$(MIGRATE_IMAGE) -path=/migrations -database "$(PROD_DB_URL)" version || true
	@echo "SSH Tüneli kapatılıyor..."
	@pkill -f "ssh -f -N $(SSH_TUNNEL_HOST)" || true

# =============================================================================
# 9. CANLI VPS KONTROL & İZLEME (Local Terminalinizden Çalıştırılır)
# =============================================================================
log-prod:
	ssh -t $(SSH_HOST_PROD) "cd $(REMOTE_PROJECT_DIR) && docker compose logs -f api"

shell-prod:
	ssh -t $(SSH_HOST_PROD) "cd $(REMOTE_PROJECT_DIR) && exec bash -l"

db-shell-prod:
	ssh -t $(SSH_HOST_PROD) "cd $(REMOTE_PROJECT_DIR) && docker compose exec -it postgres psql -U \$$DB_USER -d \$$DB_NAME"

# =============================================================================
# 10. PRODUCTION DEPLOY & SUNUCU GÜNCELLEME (VPS Tarafında Çalışır)
# =============================================================================
update:
	@echo "1. Git repodan son değişiklikler çekiliyor..."
	git pull origin main
	@echo "2. GHCR üzerinden güncel konteyner imajı çekiliyor..."
	docker compose pull api
	@echo "3. Servisler güncel ayarlarla ayağa kaldırılıyor..."
	docker compose up -d api nginx
	@echo "4. Kullanılmayan eski Docker imajları temizleniyor..."
	docker image prune -f
	@echo ">> Güncelleme tamamlandı!"
