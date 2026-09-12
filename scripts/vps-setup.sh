#!/usr/bin/env bash
set -e

echo "=== 1. Paket Listesi Güncelleniyor ve Temel Araçlar Kuruluyor ==="
sudo apt-get update -y
sudo apt-get install -y curl ca-certificates

echo "=== 2. Docker ve Docker Compose Kuruluyor ==="
# Docker resmi kurulum scripti ile Docker Engine ve Compose plugin kurulur
curl -fsSL https://get.docker.com | sudo sh

echo "=== 3. Ortak Docker Ağı (gateway) Oluşturuluyor ==="
# Konteynerlerin birbirini görmesini sağlayan harici bridge ağı
sudo docker network inspect gateway >/dev/null 2>&1 || sudo docker network create gateway

echo "=== 4. Nginx Kuruluyor ==="
sudo apt-get install -y nginx

echo "=== 5. Varsayılan (Default) Site Kaldırılıyor ==="
# Ubuntu'nun gelen 80 portunu ele geçiren varsayılan sitesini devreden çıkarır
sudo rm -f /etc/nginx/sites-enabled/default

echo "=== 6. Sertifikalar İçin Genel Dizin Açılıyor ==="
# İleride projelerin certs klasörlerinin geleceği ortak alan
sudo mkdir -p /etc/nginx/certs
sudo chmod 755 /etc/nginx/certs

echo "=== 7. Güvenlik Duvarı (UFW) Kontrol Ediliyor ==="
# UFW aktifse bağlantının kopmaması için SSH ve Nginx portları açılır
if command -v ufw >/dev/null 2>&1; then
    sudo ufw allow OpenSSH
    sudo ufw allow 'Nginx Full'
fi

echo "=== 8. Servisler Başlatılıyor ve Açılışa Ekleniyor ==="
sudo systemctl enable docker
sudo systemctl start docker

sudo systemctl enable nginx
sudo systemctl restart nginx

echo "=== VPS Kurulumu Başarıyla Tamamlandı! ==="
