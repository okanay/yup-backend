#!/usr/bin/env bash
set -e

echo "=== 1. Paket Listesi Güncelleniyor ve Nginx Kuruluyor ==="
sudo apt-get update -y
sudo apt-get install -y nginx

echo "=== 2. Varsayılan (Default) Site Kaldırılıyor ==="
# Ubuntu'nun gelen 80 portunu ele geçiren varsayılan sitesini devreden çıkarır
sudo rm -f /etc/nginx/sites-enabled/default

echo "=== 3. Sertifikalar İçin Genel Dizin Açılıyor ==="
# İleride projelerin certs klasörlerinin geleceği ortak alan
sudo mkdir -p /etc/nginx/certs
sudo chmod 755 /etc/nginx/certs

echo "=== 4. Güvenlik Duvarı (UFW) Kontrol Ediliyor ==="
# Sunucuda UFW aktifse 80 ve 443 portlarını dış dünyaya açar
if command -v ufw >/dev/null 2>&1; then
    sudo ufw allow 'Nginx Full'
fi

echo "=== 5. Nginx Servisi Başlatılıyor ve Açılışa Ekleniyor ==="
sudo systemctl enable nginx
sudo systemctl restart nginx

echo "=== Nginx Kurulumu Başarıyla Tamamlandı! ==="
