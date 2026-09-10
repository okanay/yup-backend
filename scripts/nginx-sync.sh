#!/usr/bin/env bash
set -e

# 1. Ortam değişkenlerini yükle
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "Hata: .env dosyası bulunamadı!"
    exit 1
fi

# Değişken kontrolleri
CONTAINER_NAME=${CONTAINER_NAME:-api}
DOMAIN=${DOMAIN:-api.backend.com}
PORT=${PORT:-8080}

CERT_DIR="/etc/nginx/certs/${CONTAINER_NAME}"
CONF_AVAILABLE="/etc/nginx/sites-available/${CONTAINER_NAME}.conf"
CONF_ENABLED="/etc/nginx/sites-enabled/${CONTAINER_NAME}.conf"

echo "=== 1. Sertifikalar Hazırlanıyor: ${CERT_DIR} ==="
sudo mkdir -p "${CERT_DIR}"
if [ -f certs/origin.pem ] && [ -f certs/origin.key ]; then
    sudo cp certs/origin.pem "${CERT_DIR}/origin.pem"
    sudo cp certs/origin.key "${CERT_DIR}/origin.key"
    sudo chmod 600 "${CERT_DIR}/origin.key"
else
    echo "Uyarı: certs/origin.pem veya certs/origin.key bulunamadı!"
fi

echo "=== 2. Nginx Konfigürasyonu Üretiliyor (${DOMAIN} -> 127.0.0.1:${PORT}) ==="
sudo bash -c "cat <<EOF > ${CONF_AVAILABLE}
# HTTP -> HTTPS Yönlendirmesi
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN};

    return 301 https://\\\$host\\\$request_uri;
}

# HTTPS - Cloudflare Origin SSL & Proxy Yapılandırması
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;
    server_name ${DOMAIN};

    ssl_certificate     ${CERT_DIR}/origin.pem;
    ssl_certificate_key ${CERT_DIR}/origin.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;

    location / {
        proxy_pass http://127.0.0.1:${PORT};
        proxy_http_version 1.1;

        proxy_set_header Connection \"\";
        proxy_set_header Host \\\$host;
        proxy_set_header X-Real-IP \\\$remote_addr;
        proxy_set_header X-Forwarded-For \\\$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \\\$scheme;

        proxy_set_header CF-Connecting-IP \\\$http_cf_connecting_ip;
        proxy_set_header CF-Ray \\\$http_cf_ray;
        proxy_set_header CF-IPCountry \\\$http_cf_ipcountry;

        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF"

echo "=== 3. Aktifleştirme ve Test ==="
sudo ln -sf "${CONF_AVAILABLE}" "${CONF_ENABLED}"
sudo nginx -t

echo "=== 4. Nginx Yeniden Yükleniyor ==="
sudo systemctl reload nginx
echo "=== Başarılı: ${DOMAIN} yönlendirmesi aktif! ==="
