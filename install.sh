#!/bin/bash

# Script one-liner untuk mengunduh dan menjalankan light-node
# Penggunaan: curl -s https://raw.githubusercontent.com/adekgemes/light-node/main/install.sh | bash

# Warna untuk output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Memulai instalasi Scavenger Airdrop Light-Node...${NC}"

# Periksa dependensi dasar
echo -e "${BLUE}Memeriksa dependensi dasar...${NC}"
command -v curl >/dev/null 2>&1 || { echo -e "${RED}Error: curl tidak ditemukan. Harap install curl terlebih dahulu.${NC}"; exit 1; }
command -v wget >/dev/null 2>&1 || { echo -e "${YELLOW}wget tidak ditemukan. Mencoba menginstall wget...${NC}"; apt-get update && apt-get install -y wget || { echo -e "${RED}Gagal menginstall wget.${NC}"; exit 1; }; }

# Unduh script utama
echo -e "${BLUE}Mengunduh script light-node.sh...${NC}"
wget -O light-node.sh https://raw.githubusercontent.com/adekgemes/light-node/main/light-node.sh
if [ $? -ne 0 ]; then
    echo -e "${RED}Gagal mengunduh script. Periksa koneksi internet Anda atau URL repository.${NC}"
    exit 1
fi

# Berikan izin eksekusi
echo -e "${BLUE}Memberikan izin eksekusi...${NC}"
chmod +x light-node.sh

# Jalankan instalasi
echo -e "${BLUE}Menjalankan instalasi...${NC}"
./light-node.sh install

# Hanya gunakan jaringan mainnet untuk Scavenger Airdrop
NETWORK="mainnet"
echo -e "${BLUE}Menggunakan jaringan mainnet untuk Scavenger Airdrop...${NC}"

# Setup node
echo -e "${BLUE}Menyiapkan node untuk jaringan $NETWORK...${NC}"
./light-node.sh setup

# Tanyakan apakah ingin langsung menjalankan node
echo -e "${BLUE}Apakah Anda ingin langsung menjalankan node?${NC}"
read -p "Jalankan node sekarang? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Memulai node...${NC}"
    ./light-node.sh start
fi

# Tampilkan informasi
echo -e "${GREEN}Instalasi selesai!${NC}"
echo -e "${YELLOW}Node telah diinstal di direktori saat ini.${NC}"
echo -e "${YELLOW}Anda dapat mengelola node dengan perintah: ./light-node.sh [command]${NC}"
echo
echo -e "${BLUE}Beberapa perintah berguna:${NC}"
echo -e "  ./light-node.sh status  ${GREEN}# Cek status node${NC}"
echo -e "  ./light-node.sh logs    ${GREEN}# Lihat log node${NC}"
echo -e "  ./light-node.sh stop    ${GREEN}# Hentikan node${NC}"
echo -e "  ./light-node.sh info    ${GREEN}# Lihat informasi node${NC}"
echo -e "  ./light-node.sh help    ${GREEN}# Tampilkan semua perintah${NC}"