BINARY_NAME=main
BINARY_PATH=./bin/$(BINARY_NAME)
CMD_PATH=./cmd/api/main.go

.PHONY: run build dev clean help

# Air ile hot-reload modunda başlatır
dev:
	@echo "Geliştirme modu (Hot-Reload) başlatılıyor..."
	air

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
