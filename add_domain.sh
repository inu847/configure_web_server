#!/bin/bash
# ------------------------------------------------------------------
# add_domain.sh - Tambah domain + SSL (Let's Encrypt) untuk Nginx
# - Meminta WEBROOT dari input (tidak default /var/www/$DOMAIN)
# - Deteksi PHP-FPM socket otomatis (fallback 127.0.0.1:9000)
# Tested: Ubuntu 20.04/22.04/24.04
# ------------------------------------------------------------------

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# -- Input ----------------------------------------------------------
read -rp "Masukkan nama domain (contoh: example.com): " DOMAIN
read -rp "Masukkan email untuk SSL Let's Encrypt: " EMAIL
read -rp "Masukkan path WEBROOT (contoh: /var/www/html/{nama_domain}): " WEBROOT

if [[ -z "${DOMAIN}" || -z "${EMAIL}" || -z "${WEBROOT}" ]]; then
  echo "ERROR: DOMAIN/EMAIL/WEBROOT tidak boleh kosong."
  exit 1
fi

# -- Dependencies ---------------------------------------------------
if ! command -v nginx >/dev/null 2>&1; then
  echo "===> Install Nginx"
  apt update
  apt install -y nginx
fi

# -- Siapkan WEBROOT ------------------------------------------------
echo "===> Membuat WEBROOT: ${WEBROOT}"
mkdir -p "${WEBROOT}"
chown -R www-data:www-data "${WEBROOT}"
chmod -R 755 "${WEBROOT}"

# Tambah index.php contoh jika belum ada
if [[ ! -f "${WEBROOT}/index.php" && ! -f "${WEBROOT}/index.html" ]]; then
  cat > "${WEBROOT}/index.php" <<'EOF'
<?php echo "OK: nginx + php-fpm + ssl ready\n"; ?>
EOF
  chown www-data:www-data "${WEBROOT}/index.php"
fi

# -- Deteksi PHP-FPM -----------------------------------------------
echo "===> Deteksi PHP-FPM socket"
PHP_SOCK=""
if compgen -G "/run/php/php*-fpm.sock" > /dev/null; then
  # ambil versi terbesar
  PHP_SOCK=$(ls /run/php/php*-fpm.sock 2>/dev/null | sort -r | head -n1 || true)
fi
if [[ -z "${PHP_SOCK}" ]]; then
  echo "Peringatan: Socket PHP-FPM tidak ditemukan. Gunakan fallback 127.0.0.1:9000"
  FASTCGI_PASS="127.0.0.1:9000"
else
  FASTCGI_PASS="unix:${PHP_SOCK}"
fi

# -- Nginx server block --------------------------------------------
NGINX_CONF="/etc/nginx/sites-available/${DOMAIN}"

echo "===> Menulis konfigurasi Nginx: ${NGINX_CONF}"
if [[ -f "${NGINX_CONF}" ]]; then
  cp -f "${NGINX_CONF}" "${NGINX_CONF}.bak.$(date +%s)"
fi

cat > "${NGINX_CONF}" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN} www.${DOMAIN};

    root ${WEBROOT};
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass ${FASTCGI_PASS};
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -sf "${NGINX_CONF}" "/etc/nginx/sites-enabled/${DOMAIN}"

echo "===> Validasi Nginx"
nginx -t

echo "===> Reload Nginx"
systemctl reload nginx

# -- Certbot --------------------------------------------------------
if ! command -v certbot >/dev/null 2>&1; then
  echo "===> Install Certbot"
  apt update
  apt install -y certbot python3-certbot-nginx
fi

echo "===> Request & install SSL (Let's Encrypt)"
certbot --nginx -d "${DOMAIN}" -d "www.${DOMAIN}" --non-interactive --agree-tos -m "${EMAIL}" --redirect

echo "===> Berhasil!"
echo "HTTP :  http://${DOMAIN}"
echo "HTTPS:  https://${DOMAIN}"
echo "Conf :  ${NGINX_CONF}"
echo "Root :  ${WEBROOT}"
0000000112