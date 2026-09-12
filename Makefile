# =============================================================================
# 1. ORTAM DEĞİŞKENLERİ
# =============================================================================
ifneq (,$(wildcard .env))
    include .env
    export
endif

# Proje Yolları ve Araç Tanımları
DIR_CMD             := ./cmd/api
DIR_BIN             := ./bin/api
DIR_TMP             := ./tmp/api
DIR_BACKUPS         := ./backups
MIGRATIONS_PATH     := $(shell pwd)/migrations
TIMESTAMP           := $(shell date +'%Y-%m-%d-%H-%M-%S')

# Varsayılan Değerler
SSH_HOST_PROD       ?= vps-root
SSH_TUNNEL_HOST     ?= vps-tunnel
REMOTE_PROJECT_DIR  ?= /home/ubuntu/yup-backend

DB_USER             ?= postgres
DB_PASSWORD         ?= postgres
DB_NAME             ?= yup_db
DB_PORT             ?= 5432
DB_SSLMODE          ?= disable

# Prod değişkenleri .env içinde tanımlı değilse doğrudan yerel değerleri miras alır
PROD_TUNNEL_PORT    ?= 5433
PROD_DB_USER        ?= $(DB_USER)
PROD_DB_PASSWORD    ?= $(DB_PASSWORD)
PROD_DB_NAME        ?= $(DB_NAME)

# Migration Aracı
MIGRATE_IMAGE       := migrate/migrate:v4.18.2
MIGRATE_NAME        := $(if $(n),$(n),$(name))
SSH_KEY_NAME        := $(if $(n),$(n),$(name))
SSH_KEY_PATH        := $(HOME)/.ssh/$(SSH_KEY_NAME)

# Migration URL Tanımları
LOCAL_MIGRATE_URL   := postgres://$(DB_USER):$(DB_PASSWORD)@host.docker.internal:$(DB_PORT)/$(DB_NAME)?sslmode=$(DB_SSLMODE)
PROD_MIGRATE_URL    := postgres://$(PROD_DB_USER):$(PROD_DB_PASSWORD)@host.docker.internal:$(PROD_TUNNEL_PORT)/$(PROD_DB_NAME)?sslmode=disable
# =============================================================================
# 2. PHONY HEDEFLERİ
# =============================================================================
.PHONY: help dev build run test clean \
        db-up db-down db-shell db-backup \
        up down restart logs ps \
        migrate-create migrate-up migrate-down migrate-force migrate-version \
        db-tunnel migrate-up-prod migrate-down-prod db-backup-prod \
        setup-vps deploy-prod log-prod shell-prod nginx-sync gen-ssh

# =============================================================================
# 3. YARDIM MENÜSÜ
# =============================================================================
help:
	@echo "================== YEREL GELİŞTİRME =================="
	@echo "  make dev                 : Air ile API'yi hot-reload modunda başlatır"
	@echo "  make build               : Yerel binary derler"
	@echo "  make run                 : Yerel binary derler ve çalıştırır"
	@echo "  make test                : Race condition kontrolüyle testleri koşar"
	@echo "  make clean               : Derleme artıklarını ve geçici dosyaları siler"
	@echo ""
	@echo "================ VERİTABANI (DOCKER) ================="
	@echo "  make db-up               : PostgreSQL konteynerini başlatır (Profile: db)"
	@echo "  make db-down             : PostgreSQL konteynerini durdurur"
	@echo "  make db-shell            : Konteyner içindeki psql CLI konsoluna bağlanır"
	@echo "  make db-backup           : Yerel veritabanının yedeğini SQL olarak alır"
	@echo ""
	@echo "================== UYGULAMA (API) ===================="
	@echo "  make up                  : API konteynerini çeker ve ayağa kaldırır"
	@echo "  make down                : API konteynerini durdurur"
	@echo "  make restart             : API konteynerini yeniden başlatır"
	@echo "  make logs                : API konteyner loglarını canlı izler"
	@echo "  make ps                  : Çalışan servislerin durumunu listeler"
	@echo ""
	@echo "================ VERİTABANI MİGRASYONU ================"
	@echo "  make migrate-create n=x  : Yeni migration SQL dosyaları oluşturur"
	@echo "  make migrate-up          : Yerel veritabanına uygulanmamış şemaları basar"
	@echo "  make migrate-down        : Yerel veritabanında son adımı geri alır"
	@echo "  make migrate-version     : Mevcut migration versiyonunu gösterir"
	@echo ""
	@echo "================ CANLI SUNUCU (VPS) =================="
	@echo "  make setup-vps           : Yeni kiralanan VPS'i sıfırdan kurar (Docker, Nginx, UFW)"
	@echo "  make db-tunnel           : Canlı veritabanına SSH tüneli açar"
	@echo "  make migrate-up-prod     : SSH tüneli üzerinden canlı veritabanına şema basar"
	@echo "  make db-backup-prod      : Canlı veritabanı yedeğini lokale indirir"
	@echo "  make deploy-prod         : VPS üzerinde kod ve imaj güncellemesi yapar"
	@echo "  make log-prod            : Canlı sunucudaki API loglarını izler"
	@echo "  make shell-prod          : VPS terminaline SSH oturumu açar"
	@echo "  make nginx-sync          : VPS Nginx yapılandırmasını senkronize eder"
	@echo "  make gen-ssh n=name      : Belirtilen isimle SSH anahtarı üretir ve panoya kopyalar"

# =============================================================================
# 4. YEREL GELİŞTİRME (Native macOS / Air)
# =============================================================================
dev:
	@echo "Air ile yerel geliştirme ortamı başlatılıyor..."
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
	@echo "Geçici dosyalar ve derleme çıktıları temizlendi."

# =============================================================================
# 5. VERİTABANI YÖNETİMİ (Docker Profile: db)
# =============================================================================
db-up:
	docker compose up -d postgres

db-down:
	docker compose stop postgres

db-shell:
	docker compose exec -it postgres psql -U $(DB_USER) -d $(DB_NAME)

db-backup:
	@mkdir -p $(DIR_BACKUPS)
	docker compose exec -T postgres pg_dump -U $(DB_USER) $(DB_NAME) > $(DIR_BACKUPS)/backup-local-$(TIMESTAMP).sql
	@echo "Yedek alındı: $(DIR_BACKUPS)/backup-local-$(TIMESTAMP).sql"

# =============================================================================
# 6. UYGULAMA SERVİSİ (Docker Compose)
# =============================================================================
up:
	docker compose pull api
	docker compose up -d api

down:
	docker compose down

restart:
	docker compose restart api

logs:
	docker compose logs -f api

ps:
	docker compose ps

# =============================================================================
# 7. YEREL MIGRATION (golang-migrate Docker Konteyneri)
# =============================================================================
migrate-create:
	@if [ -z "$(MIGRATE_NAME)" ]; then echo "Hata: Migration ismi eksik! Örnek: make migrate-create n=init"; exit 1; fi
	@mkdir -p $(MIGRATIONS_PATH)
	docker run --rm -u $(shell id -u):$(shell id -g) -v $(MIGRATIONS_PATH):/migrations \
		$(MIGRATE_IMAGE) create -ext sql -dir /migrations -seq $(MIGRATE_NAME)

migrate-up:
	docker run --rm -v $(MIGRATIONS_PATH):/migrations --add-host=host.docker.internal:host-gateway \
		$(MIGRATE_IMAGE) -path=/migrations -database "$(LOCAL_MIGRATE_URL)" up

migrate-down:
	docker run --rm -v $(MIGRATIONS_PATH):/migrations --add-host=host.docker.internal:host-gateway \
		$(MIGRATE_IMAGE) -path=/migrations -database "$(LOCAL_MIGRATE_URL)" down 1

migrate-force:
	@if [ -z "$(v)" ]; then echo "Hata: Versiyon eksik! Örnek: make migrate-force v=1"; exit 1; fi
	docker run --rm -v $(MIGRATIONS_PATH):/migrations --add-host=host.docker.internal:host-gateway \
		$(MIGRATE_IMAGE) -path=/migrations -database "$(LOCAL_MIGRATE_URL)" force $(v)

migrate-version:
	docker run --rm -v $(MIGRATIONS_PATH):/migrations --add-host=host.docker.internal:host-gateway \
		$(MIGRATE_IMAGE) -path=/migrations -database "$(LOCAL_MIGRATE_URL)" version

# =============================================================================
# 8. CANLI ORTAM (PROD) İŞLEMLERİ (SSH & Tünelleme)
# =============================================================================
setup-vps:
	@echo "VPS altyapı kurulumu başlatılıyor ($(SSH_HOST_PROD))..."
	@ssh $(SSH_HOST_PROD) "bash -s" < scripts/vps-setup.sh
	@echo "VPS altyapı kurulumu tamamlandı."

db-tunnel:
	@echo "Canlı DB tüneli $(PROD_TUNNEL_PORT) portunda açılıyor... (Kapatmak için Ctrl+C)"
	@ssh -N $(SSH_TUNNEL_HOST)

migrate-up-prod:
	@echo "SSH Tüneli başlatılıyor..."
	@ssh -f -N $(SSH_TUNNEL_HOST)
	@sleep 2
	@echo "Canlı veritabanına migration uygulanıyor..."
	@docker run --rm -v $(MIGRATIONS_PATH):/migrations --add-host=host.docker.internal:host-gateway \
		$(MIGRATE_IMAGE) -path=/migrations -database "$(PROD_MIGRATE_URL)" up || true
	@echo "SSH Tüneli sonlandırılıyor..."
	@pkill -f "ssh -f -N $(SSH_TUNNEL_HOST)" || true

migrate-down-prod:
	@echo "SSH Tüneli başlatılıyor..."
	@ssh -f -N $(SSH_TUNNEL_HOST)
	@sleep 2
	@echo "Canlı veritabanında son migration geri alınıyor..."
	@docker run --rm -v $(MIGRATIONS_PATH):/migrations --add-host=host.docker.internal:host-gateway \
		$(MIGRATE_IMAGE) -path=/migrations -database "$(PROD_MIGRATE_URL)" down 1 || true
	@echo "SSH Tüneli sonlandırılıyor..."
	@pkill -f "ssh -f -N $(SSH_TUNNEL_HOST)" || true

db-backup-prod:
	@mkdir -p $(DIR_BACKUPS)
	@echo "Canlı veritabanı yedeği alınıyor..."
	@ssh $(SSH_HOST_PROD) "docker compose -f $(REMOTE_PROJECT_DIR)/docker-compose.yml exec -T postgres pg_dump -U \$$DB_USER \$$DB_NAME" > $(DIR_BACKUPS)/backup-prod-$(TIMESTAMP).sql
	@echo "Canlı yedek kaydedildi: $(DIR_BACKUPS)/backup-prod-$(TIMESTAMP).sql"

deploy-prod:
	ssh -t $(SSH_HOST_PROD) "cd $(REMOTE_PROJECT_DIR) && git pull origin main && docker compose pull api && docker compose up -d api && docker image prune -f"

log-prod:
	ssh -t $(SSH_HOST_PROD) "cd $(REMOTE_PROJECT_DIR) && docker compose logs -f api"

shell-prod:
	ssh -t $(SSH_HOST_PROD) "cd $(REMOTE_PROJECT_DIR) && exec bash -l"

nginx-sync:
	ssh -t $(SSH_HOST_PROD) "cd $(REMOTE_PROJECT_DIR) && chmod +x scripts/nginx-sync.sh && ./scripts/nginx-sync.sh"

gen-ssh:
	@if [ -z "$(SSH_KEY_NAME)" ]; then \
		echo "Uyarı: SSH anahtar ismi eksik! Örnek: make gen-ssh n=hetzner_vps"; \
		exit 1; \
	elif ! printf '%s' "$(SSH_KEY_NAME)" | grep -Eq '^[a-zA-Z0-9._-]+$$'; then \
		echo "Uyarı: SSH anahtar ismi yalnızca harf, rakam, nokta, alt çizgi ve tire içerebilir."; \
		exit 1; \
	elif [ -f "$(SSH_KEY_PATH)" ]; then \
		echo "Anahtar zaten mevcut: $(SSH_KEY_PATH)"; \
	else \
		mkdir -p "$(HOME)/.ssh"; \
		ssh-keygen -t ed25519 -C "$(SSH_KEY_NAME)" -f "$(SSH_KEY_PATH)" -N ""; \
		echo "Yeni anahtar üretildi: $(SSH_KEY_PATH)"; \
	fi; \
	pbcopy < "$(SSH_KEY_PATH).pub"; \
	echo ">> Public key doğrudan panoya (clipboard) kopyalandı! Hetzner paneline yapıştırabilirsiniz (CMD+V)."; \
	echo ""; \
	echo "Sunucuyu açtıktan sonra ~/.ssh/config dosyanıza şunu ekleyin:"; \
	echo "--------------------------------------------------"; \
	echo "Host vps-root"; \
	echo "    HostName <vps-ip-address-v4>"; \
	echo "    User root"; \
	echo "    IdentityFile $(SSH_KEY_PATH)"; \
	echo "--------------------------------------------------"
