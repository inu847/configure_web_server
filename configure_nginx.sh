#!/bin/bash

# ------------------------------------------------------------------
# Script Install Laravel Stack (Nginx + PHP + MySQL + Composer)
# Tested on Ubuntu 20.04 (Focal)
# ------------------------------------------------------------------

set -e  # stop jika ada error

echo "===> Update & Upgrade Packages"
apt update && apt upgrade -y

echo "===> Install Nginx"
apt install nginx -y

echo "===> Tambah Repository PHP Ondrej"
add-apt-repository ppa:ondrej/php -y
apt update

echo "===> Install PHP 8.3 dan Ekstensi"
apt install php8.3 php8.3-fpm php8.3-mysql php8.3-mbstring php8.3-xml \
php8.3-bcmath php8.3-curl php8.3-zip unzip -y

echo "===> Install Composer"
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
chmod +x /usr/local/bin/composer

echo "===> Install MySQL Server"
apt install mysql-server -y

echo "===> Setup Secure Installation (Manual Step)"
mysql_secure_installation

echo "===> Konfigurasi MySQL User"
echo "Masukkan informasi user MySQL baru:"
read -p "Username: " mysql_username
read -s -p "Password: " mysql_password
echo  # untuk newline setelah password input

# Validasi input tidak kosong
if [[ -z "$mysql_username" || -z "$mysql_password" ]]; then
    echo "Error: Username dan password tidak boleh kosong!"
    exit 1
fi

# Escape special characters untuk keamanan
mysql_username_escaped=$(printf '%s\n' "$mysql_username" | sed "s/['\"]/\\\&/g")
mysql_password_escaped=$(printf '%s\n' "$mysql_password" | sed "s/['\"]/\\\&/g")

echo "Membuat user MySQL: $mysql_username"
mysql -u root <<EOF
CREATE USER IF NOT EXISTS '$mysql_username_escaped'@'%' IDENTIFIED BY '$mysql_password_escaped';
GRANT ALL PRIVILEGES ON *.* TO '$mysql_username_escaped'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

echo "User MySQL '$mysql_username' berhasil dibuat!"

echo "===> Update MySQL bind-address"
sed -i "s/^bind-address\s*=.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
if ! grep -q "mysqlx-bind-address" /etc/mysql/mysql.conf.d/mysqld.cnf; then
  echo "mysqlx-bind-address = 0.0.0.0" >> /etc/mysql/mysql.conf.d/mysqld.cnf
else
  sed -i "s/^mysqlx-bind-address\s*=.*/mysqlx-bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
fi

echo "===> Open Port"
# ufw allow 80/tcp
# ufw allow 80/tcp
# ufw allow 443/tcp
# ufw allow 3306
# ufw allow 22
# ufw enable

ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3306/tcp
ufw allow 22/tcp
ufw --force enable

echo "===> Restart MySQL Service"
systemctl restart mysql

echo "===> Instalasi Selesai!"
echo "Silakan cek service: nginx, php8.3-fpm, dan mysql."
