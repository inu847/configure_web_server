# Setup Server Scripts untuk VPS Ubuntu

Kumpulan script untuk setup server LEMP (Linux, Nginx, MySQL, PHP) di VPS Ubuntu dengan fitur otomatis dan interaktif.

## 📋 Daftar Script

1. **`configure_nginx.sh`** - Install dan konfigurasi LEMP stack lengkap
2. **`generate_pubkey.sh`** - Generate SSH public key untuk GitHub
3. **`add_domain.sh`** - Tambah domain dengan SSL Let's Encrypt

## 🔧 Prasyarat

- VPS Ubuntu 20.04/22.04/24.04
- Akses root atau sudo privileges
- Koneksi internet yang stabil
- Domain yang sudah pointing ke IP VPS (untuk `add_domain.sh`)

## 🚀 Cara Penggunaan

### 1. Persiapan Awal

```bash
# Login ke VPS sebagai root atau user dengan sudo
ssh root@your-vps-ip

# Update sistem
sudo apt update && sudo apt upgrade -y

# Download atau upload script ke VPS
# Pastikan semua script memiliki permission execute
chmod +x *.sh
```

### 2. Install LEMP Stack

```bash
# Jalankan script konfigurasi utama
sudo ./configure_nginx.sh
```

**Yang akan diinstall:**
- Nginx web server
- PHP 8.3 + ekstensi (FPM, MySQL, mbstring, xml, bcmath, curl, zip)
- MySQL Server
- Composer
- Firewall configuration (port 80, 443, 3306)

**Input yang diperlukan:**
- Username MySQL baru
- Password MySQL (input tersembunyi)
- Konfigurasi MySQL secure installation (manual)

### 3. Generate SSH Key untuk GitHub

```bash
# Generate SSH public key
./generate_pubkey.sh
```

**Input yang diperlukan:**
- Email address untuk SSH key

**Output:**
- SSH key pair akan dibuat di `~/.ssh/`
- Public key akan ditampilkan untuk dicopy ke GitHub
- Link pengaturan GitHub SSH keys: https://github.com/settings/keys

### 4. Tambah Domain dengan SSL

```bash
# Tambah domain baru dengan SSL otomatis
sudo ./add_domain.sh
```

**Input yang diperlukan:**
- Nama domain (contoh: example.com)
- Email untuk SSL Let's Encrypt
- Path webroot (contoh: /var/www/html/example.com)

**Fitur:**
- Auto-detect PHP-FPM socket
- SSL certificate dari Let's Encrypt
- Redirect HTTP ke HTTPS
- Nginx server block configuration

## 📁 Struktur File Setelah Instalasi

```
/etc/nginx/sites-available/    # Konfigurasi domain
/etc/nginx/sites-enabled/      # Domain yang aktif
/var/www/html/                 # Document root default
~/.ssh/                        # SSH keys
/etc/mysql/                    # Konfigurasi MySQL
```

## 🔒 Keamanan

- Password MySQL diinput secara tersembunyi
- Input validation untuk mencegah input kosong
- Escape special characters untuk keamanan SQL
- Firewall dikonfigurasi otomatis
- SSL certificate otomatis dari Let's Encrypt

## 🐛 Troubleshooting

### MySQL Connection Issues
```bash
# Cek status MySQL
sudo systemctl status mysql

# Restart MySQL jika diperlukan
sudo systemctl restart mysql
```

### Nginx Configuration Issues
```bash
# Test konfigurasi Nginx
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

### SSL Certificate Issues
```bash
# Cek status certificate
sudo certbot certificates

# Renew certificate manual
sudo certbot renew
```

### PHP-FPM Issues
```bash
# Cek status PHP-FPM
sudo systemctl status php8.3-fpm

# Restart PHP-FPM
sudo systemctl restart php8.3-fpm
```

## 📝 Catatan Penting

1. **Backup**: Selalu backup konfigurasi sebelum menjalankan script
2. **Domain**: Pastikan domain sudah pointing ke IP VPS sebelum menjalankan `add_domain.sh`
3. **Firewall**: Script akan mengaktifkan UFW firewall
4. **MySQL**: Catat username dan password MySQL yang dibuat
5. **SSH Key**: Simpan private key dengan aman

## 🔄 Urutan Eksekusi yang Disarankan

1. `configure_nginx.sh` - Setup dasar server
2. `generate_pubkey.sh` - Setup SSH key untuk development
3. `add_domain.sh` - Tambah domain sesuai kebutuhan

## 📞 Support

Jika mengalami masalah:
1. Cek log error di `/var/log/nginx/error.log`
2. Cek log MySQL di `/var/log/mysql/error.log`
3. Gunakan `systemctl status [service]` untuk cek status service

---

**Tested on:** Ubuntu 20.04, 22.04, 24.04  
**Last Updated:** 2024