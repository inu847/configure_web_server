#!/bin/bash

# ------------------------------------------------------------------
# Script Install Laravel Stack (Nginx + PHP + MySQL + Composer)
# Tested on Ubuntu 20.04 (Focal)
# ------------------------------------------------------------------

set -e  # stop jika ada error

echo "===> Generate SSH Public Key"
read -p "Masukkan email untuk SSH key: " user_email

# Validasi input email tidak kosong
if [[ -z "$user_email" ]]; then
    echo "Error: Email tidak boleh kosong!"
    exit 1
fi

echo "Membuat SSH key dengan email: $user_email"
ssh-keygen -t ed25519 -C "$user_email"

echo "===> Untuk Connect Gitgub Masukkan Kedalam SSH di pengaturan github https://github.com/settings/keys"
cat ~/.ssh/id_ed25519.pub