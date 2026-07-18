sudo unlink /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
sudo ss -lntp '( sport = :80 or sport = :443 )'

sudo nano /etc/nginx/sites-available/api.backend.com

server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name api.backend.com;

    ssl_certificate     /etc/letsencrypt/live/api.backend.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.backend.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:8080;

        proxy_set_header Host $host;
        proxy_set_header CF-Connecting-IP $http_cf_connecting_ip;
        proxy_set_header X-Forwarded-Proto https;
    }
}

sudo ln -s /etc/nginx/sites-available/api.backend.com \
  /etc/nginx/sites-enabled/api.backend.com
