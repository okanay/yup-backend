BINARY_NAME=main
BINARY_PATH=./bin/$(BINARY_NAME)
CMD_PATH=./cmd/api

.PHONY: dev dev-labs dev-api build run clean

# Air ile hot-reload modunda başlatır
dev: dev-labs

dev-labs:
	@echo "Labs modu (Hot-Reload) başlatılıyor..."
	air \
		--build.cmd "go build -o ./tmp/labs ./cmd/labs" \
		--build.entrypoint "./tmp/labs"

dev-api:
	@echo "API modu (Hot-Reload) başlatılıyor..."
	air \
		--build.cmd "go build -o ./tmp/api ./cmd/api" \
		--build.entrypoint "./tmp/api"

# Uygulamayı derler
build:
	@echo "Uygulama derleniyor..."
	@mkdir -p bin
	go build -o $(BINARY_PATH) $(CMD_PATH)
	@echo "Derleme tamamlandı: $(BINARY_PATH)"

# Önce derler, sonra çalıştırır
run: build
	@echo "Uygulama başlatılıyor..."
	$(BINARY_PATH)

clean:
	@echo "Temizlik yapılıyor..."
	@rm -f bin/$(BINARY_NAME)
	@rm -rf tmp
	@echo "Temizlendi."
