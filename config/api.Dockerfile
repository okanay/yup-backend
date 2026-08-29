# =============================================================================
# AŞAMA 1: BUILDER (Derleme Ortamı)
# =============================================================================
# Go derleyicisini ve gerekli araçları barındıran resmi hafif Alpine imajı.
# 'AS builder' ifadesi bu aşamaya bir isim verir; sonraki aşamalardan buraya
# referans verilerek sadece üretilen binary çekilecektir.
FROM golang:1.26-alpine AS builder

# Konteyner içindeki aktif çalışma dizinini belirler.
WORKDIR /app

# Sadece bağımlılık tanımlarını kopyalar.
# Go kodları kopyalanmadan önce bu adımın yapılması, bağımlılıkların
# Docker layer önbelleğinde (layer caching) tutulmasını sağlar.
COPY go.mod go.sum ./

# Bağımlılıkları indirir.
# --mount=type=cache: İndirilen Go modüllerini host makinenin BuildKit önbelleğinde tutar.
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

# Projenin tüm kaynak kodlarını çalışma dizinine (/app) kopyalar.
COPY . .

# Go binary'sini derler.
# - CGO_ENABLED=0: C kütüphanelerine (glibc) olan bağımlılığı keser, tamamen statik binary üretir.
# - GOOS=linux: Hedef işletim sisteminin Linux olduğunu kesinleştirir.
# - -trimpath: Dosya yolu izlerini binary'den siler.
# - -ldflags="-w -s": Hata ayıklama sembollerini temizleyerek boyutu küçültür.
# - -o /api: Çıktı dosyasını kök dizinde 'api' adıyla oluşturur.
# - ./cmd/api: Derlenecek 'main.go' dosyasının bulunduğu paket dizini.
RUN --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/go/pkg/mod \
    CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-w -s" -o /api ./cmd/api

# =============================================================================
# AŞAMA 2: PRODUCTION RUNTIME (Çalışma Ortamı)
# =============================================================================
# Google'ın yalnızca CA sertifikaları, tzdata (zaman dilimleri) ve temel sistem
# dosyalarını içeren ~2-3 MB'lık ultra minimal distroless imajı.
# İçinde Go SDK, derleyici, apt/apk paket yöneticisi, bash/sh komut satırı YOKTUR.
FROM gcr.io/distroless/static-debian12

# Uygulamanın çalışacağı dizin
WORKDIR /app

# İlk aşamada (builder) derlenen saf ikili dosyayı (binary) kopyalar.
# Kaynak kodlar, Go SDK veya ara dosyalar bu aşamaya ASLA geçmez.
COPY --from=builder /api /app/api

# Güvenlik standardı: Konteyneri 'root' (UID 0) yerine 'nonroot' (UID 65532) kullanıcısıyla çalıştırır.
USER nonroot:nonroot

# Konteyner başlatıldığında çalıştırılacak varsayılan komut.
CMD ["/app/api"]
