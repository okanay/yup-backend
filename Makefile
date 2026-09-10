# =============================================================================
# 1. ORTAM DEĞİŞKENLERİ VE DOCKER COMPOSE KOMUTLARI
# =============================================================================
-include .env
export

# Compose Dosya Yolları
INFRA_COMPOSE       := docker compose -f config/infra.docker-compose.yml
APP_COMPOSE         := docker compose -f docker-compose.yml

# SSH Yapılandırması (~/.ssh/config ile eşleşir)
SSH_HOST_PROD       := vps-root
SSH_TUNNEL_HOST     := yup-tunnel
REMOTE_PROJECT_DIR  := /home/ubuntu/yup-backend

# Proje Yolları
DIR_CMD             := ./cmd/api
DIR_BIN             := ./bin/api
DIR_TMP             := ./tmp/api
DIR_BACKUPS         := ./backups
MIGRATIONS_PATH     := $(shell pwd)/migrations

# Zaman Damgası
TIMESTAMP           := $(shell date +'%Y-%m-%d-%H-%M-%S')

# Migration Aracı
MIGRATE_IMAGE       := migrate/migrate:v4.18.2
MIGRATE_NAME        := $(if $(n),$(n),$(name))

# Veritabanı URL Tanımları
LOCAL_DB_PORT       ?= 5432
LOCAL_DB_URL        := postgres://$(DB_USER):$(DB_PASSWORD)@host.docker.internal:$(LOCAL_DB_PORT)/$(DB_NAME)?sslmode=disable

PROD_TUNNEL_PORT    ?= 5433
PROD_DB_URL         := postgres://$(PROD_DB_USER):$(PROD_DB_PASSWORD)@host.docker.internal:$(PROD_TUNNEL_PORT)/$(PROD_DB_NAME)?sslmode=disable

# =============================================================================
# 2. PHONY HEDEFLERİ
# =============================================================================
.PHONY: help dev build run clean test \
        infra-up infra-down db-up db-down nginx-reload \
        up down restart logs ps \
        db-shell db-backup db-backup-prod \
        migrate-create migrate-up migrate-down migrate-force migrate-version \
        db-tunnel migrate-up-prod migrate-down-prod migrate-force-prod migrate-version-prod \
        log-prod shell-prod db-shell-prod update nginx-sync

# =============================================================================
# 3. YARDIM MENÜSÜ
# =============================================================================
help:
	@echo "--- YEREL GELİŞTİRME ---"
	@echo "  make dev                 : Air ile API'yi hot-reload modunda başlatır"
	@echo "  make build               : Yerel binary derler"
	@echo "  make run                 : Yerel binary derleyip çalıştırır"
	@echo "  make test                : Race detector ile testleri çalıştırır"
	@echo "  make clean               : Derleme artıklarını siler"
	@echo ""
	@echo "--- ALTYAPI YÖNETİMİ (INFRA: POSTGRES & NGINX) ---"
	@echo "  make infra-up            : Ortak Postgres ve Nginx altyapısını kaldırır"
	@echo "  make infra-down          : Altyapı servislerini durdurur"
	@echo "  make db-up               : Yalnızca PostgreSQL konteynerini başlatır (Air için)"
	@echo "  make db-down             : PostgreSQL konteynerini durdurur"
	@echo "  make nginx-reload        : Nginx'i kesintisiz yeniden yükler"
	@echo ""
	@echo "--- UYGULAMA SERVİSİ (YUP API) ---"
	@echo "  make up                  : API konteynerini çeker ve ayağa kaldırır"
	@echo "  make down                : API konteynerini durdurur"
	@echo "  make restart             : API konteynerini yeniden başlatır"
	@echo "  make logs                : API loglarını canlı izler"
	@echo "  make ps                  : Konteynerlerin durumunu listeler"
	@echo ""
	@echo "--- VERİTABANI & MİGRASYON ---"
	@echo "  make db-shell            : Yerel psql konsoluna bağlanır"
	@echo "  make migrate-create n=x  : Yeni migration dosyası açar"
	@echo "  make migrate-up          : Yerel migrationları uygular"
	@echo "  make migrate-down        : Yerel son migrationı geri alır"
	@echo "  make migrate-up-prod     : SSH tüneliyle canlı DB'ye migrate basar"
	@echo ""
	@echo "--- CI/CD & VPS DAĞITIMI ---"
	@echo "  make update              : VPS üzerinde API'yi sıfır kesintiyle günceller"
	@echo "  make nginx-sync          : Nginx yapılandırmasını günceller"

# =============================================================================
# 4. YEREL GELİŞTİRME (Native Go / Air)
# =============================================================================
dev:
	@echo "Air başlatılıyor..."
	air --build.cmd "go build -o $(DIR_TMP) $(DIR_CMD)" --build.entrypoint "$(DIR_TMP)"

build:
	@mkdir -p ./bin
	go build -o $(DIR_BIN) $(DIR_CMD)

run: build
	$(DIR_BIN)

test:
	go test -v -race ./...

clean:
	@rm -rf ./bin ./tmp
	@echo "Geçici dosyalar temizlendi."

# =============================================================================
# 5. ALTYAPI SERVİSLERİ (POSTGRES & NGINX)
# =============================================================================
# Gateway ağını kontrol eder, yoksa oluşturup altyapıyı kaldırır
infra-up:
	@docker network inspect gateway >/dev/null 2>&1 || docker network create gateway
	$(INFRA_COMPOSE) up -d

infra-down:
	$(INFRA_COMPOSE) down

# Air ile geliştirme yaparken sadece veritabanını ayağa kaldırır
db-up:
	@docker network inspect gateway >/dev/null 2>&1 || docker network create gateway
	$(INFRA_COMPOSE) up -d postgres

db-down:
	$(INFRA_COMPOSE) stop postgres

nginx-reload:
	docker exec central_nginx nginx -s reload

# =============================================================================
# 6. UYGULAMA (API) SERVİSİ
# =============================================================================
up:
	@docker network inspect gateway >/dev/null 2>&1 || docker network create gateway
	$(APP_COMPOSE) pull
	$(APP_COMPOSE) up -d

down:
	$(APP_COMPOSE) down

restart: down up

logs:
	$(APP_COMPOSE) logs -f api

ps:
	$(APP_COMPOSE) ps

# =============================================================================
# 7. VERİTABANI YÖNETİMİ & YEDEKLER
# =============================================================================
db-shell:
	docker exec -it central_postgres psql -U $(DB_USER) -d $(DB_NAME)

db-backup:
	@mkdir -p $(DIR_BACKUPS)
	docker exec -T central_postgres pg_dump -U $(DB_USER) $(DB_NAME) > $(DIR_BACKUPS)/db-$(TIMESTAMP)-local.sql
	@echo "Yerel yedek alındı: $(DIR_BACKUPS)/db-$(TIMESTAMP)-local.sql"

db-backup-prod:
	@mkdir -p $(DIR_BACKUPS)
	@echo "Canlı veritabanı yedeği SSH üzerinden çekiliyor..."
	@ssh $(SSH_HOST_PROD) "docker exec -T central_postgres pg_dump -U \$$PROD_DB_USER \$$PROD_DB_NAME" > $(DIR_BACKUPS)/db-$(TIMESTAMP)-prod.sql
	@echo "Canlı yedek kaydedildi: $(DIR_BACKUPS)/db-$(TIMESTAMP)-prod.sql"

# =============================================================================
# 8. YEREL MIGRATION (Docker Tabanlı)
# =============================================================================
migrate-create:
	@if [ -z "$(MIGRATE_NAME)" ]; then echo "Hata: İsim belirtilmedi. Örnek: make migrate-create n=init"; exit 1; fi
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
	@if [ -z "$(v)" ]; then echo "Hata: Versiyon belirtilmedi. Örnek: make migrate-force v=1"; exit 1; fi
	docker run --rm -v $(MIGRATIONS_PATH):/migrations --add-host=host.docker.internal:host-gateway \
		$(MIGRATE_IMAGE) -path=/migrations -database "$(LOCAL_DB_URL)" force $(v)

migrate-version:
	docker run --rm -v $(MIGRATIONS_PATH):/migrations --add-host=host.docker.internal:host-gateway \
		$(MIGRATE_IMAGE) -path=/migrations -database "$(LOCAL_DB_URL)" version

# =============================================================================
# 9. CANLI (PROD) MIGRATION (SSH Tüneli ile)
# =============================================================================
db-tunnel:
	@echo "Canlı DB SSH tüneli $(PROD_TUNNEL_PORT) portunda açılıyor..."
	@ssh -N $(SSH_TUNNEL_HOST)

migrate-up-prod:
	@echo "SSH Tüneli açılıyor..."
	@ssh -f -N $(SSH_TUNNEL_HOST)
	@sleep 2
	@echo "Canlı DB migration uygulanıyor..."
	@docker run --rm -v $(MIGRATIONS_PATH):/migrations --add-host=host.docker.internal:host-gateway \
		$(MIGRATE_IMAGE) -path=/migrations -database "$(PROD_DB_URL)" up || true
	@echo "SSH Tüneli kapatılıyor..."
	@pkill -f "ssh -f -N $(SSH_TUNNEL_HOST)" || true

migrate-down-prod:
	@echo "SSH Tüneli açılıyor..."
	@ssh -f -N $(SSH_TUNNEL_HOST)
	@sleep 2
	@echo "Canlı DB migration geri alınıyor..."
	@docker run --rm -v $(MIGRATIONS_PATH):/migrations --add-host=host.docker.internal:host-gateway \
		$(MIGRATE_IMAGE) -path=/migrations -database "$(PROD_DB_URL)" down 1 || true
	@echo "SSH Tüneli kapatılıyor..."
	@pkill -f "ssh -f -N $(SSH_TUNNEL_HOST)" || true

# =============================================================================
# 10. CANLI VPS İZLEME VE BAĞLANTI (Yerel Terminalden)
# =============================================================================
log-prod:
	ssh -t $(SSH_HOST_PROD) "cd $(REMOTE_PROJECT_DIR) && docker compose logs -f api"

shell-prod:
	ssh -t $(SSH_HOST_PROD) "cd $(REMOTE_PROJECT_DIR) && exec bash -l"

db-shell-prod:
	ssh -t $(SSH_HOST_PROD) "docker exec -it central_postgres psql -U \$$PROD_DB_USER -d \$$PROD_DB_NAME"

# =============================================================================
# 11. CI/CD & DAĞITIM (VPS Üzerinde Koşar)
# =============================================================================
update:
	@echo "1. Git repodan güncellemeler alınıyor..."
	git pull origin main
	@echo "2. Yeni imaj çekiliyor..."
	$(APP_COMPOSE) pull api
	@echo "3. API güncelleniyor (Postgres ve Nginx kesintiye uğramaz)..."
	$(APP_COMPOSE) up -d --remove-orphans api
	@echo "4. Eski imaj artıkları siliniyor..."
	docker image prune -f
	@echo ">> Dağıtım başarıyla tamamlandı!"

nginx-sync:
	chmod +x scripts/nginx-sync.sh
	./scripts/nginx-sync.sh
