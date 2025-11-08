#!/bin/bash
# ------------------------------------------------------------------
# setup_laravel_local.sh - Setup Laravel via Nginx on custom port (e.g., 8000)
# Untuk akses via: http://<IP_LOCAL>:8000
# - Tidak pakai SSL (karena IP)
# - Port bisa diatur (default: 8000)
# ------------------------------------------------------------------

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# -- Input ----------------------------------------------------------
read -rp "Masukkan IP lokal (contoh: 192.168.1.10 atau 0.0.0.0): " IP_ADDR
read -rp "Masukkan port (default: 8000): " PORT
PORT="${PORT:-8000}"
read -rp "Masukkan path WEBROOT (contoh: /var/www/html/cbt): " WEBROOT

if [[ -z "${IP_ADDR}" || -z "${WEBROOT}" ]]; then
  echo "ERROR: IP atau WEBROOT tidak boleh kosong."
  exit 1
fi

# -- Dependencies ---------------------------------------------------
echo "===> Memastikan Nginx dan PHP-FPM terinstal"
apt update
apt install -y nginx php-fpm php-cli php-mbstring php-xml php-curl php-mysql

# -- Siapkan WEBROOT ------------------------------------------------
echo "===> Membuat WEBROOT: ${WEBROOT}"
mkdir -p "${WEBROOT}"
chown -R www-data:www-data "${WEBROOT}"
chmod -R 755 "${WEBROOT}"

# Tambah index.php contoh jika Laravel belum ada
if [[ ! -f "${WEBROOT}/index.php" && ! -f "${WEBROOT}/index.php" ]]; then
  mkdir -p "${WEBROOT}"
  cat > "${WEBROOT}/index.php" <<'EOF'
<?php
echo "<h1>Laravel Ready (via Nginx on port 8000)</h1>";
if (file_exists('artisan')) {
    echo "<p>✅ Terdeteksi: Ini adalah project Laravel.</p>";
} else {
    echo "<p>ℹ️ Tempatkan project Laravel di sini dan pastikan tersedia.</p>";
}
?>
EOF
  chown www-data:www-data "${WEBROOT}/index.php"
fi

# -- Deteksi PHP-FPM -----------------------------------------------
echo "===> Deteksi PHP-FPM socket"
PHP_SOCK=""
if compgen -G "/run/php/php*-fpm.sock" > /dev/null; then
  PHP_SOCK=$(ls /run/php/php*-fpm.sock 2>/dev/null | sort -r | head -n1 || true)
fi
if [[ -z "${PHP_SOCK}" ]]; then
  echo "Peringatan: Socket PHP-FPM tidak ditemukan. Gunakan fallback 127.0.0.1:9000"
  FASTCGI_PASS="127.0.0.1:9000"
else
  FASTCGI_PASS="unix:${PHP_SOCK}"
fi

# -- Nginx server block (custom port) -------------------------------
NGINX_CONF="/etc/nginx/sites-available/laravel-local-${PORT}"

echo "===> Menulis konfigurasi Nginx: ${NGINX_CONF}"
if [[ -f "${NGINX_CONF}" ]]; then
  cp -f "${NGINX_CONF}" "${NGINX_CONF}.bak.$(date +%s)"
fi

cat > "${NGINX_CONF}" <<EOF
server {
    listen ${PORT};
    listen [::]:${PORT};

    # IP atau wildcard (0.0.0.0)
    server_name _ ${IP_ADDR};

    root ${WEBROOT};
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
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

# Aktifkan config
ln -sf "${NGINX_CONF}" "/etc/nginx/sites-enabled/laravel-local-${PORT}"
