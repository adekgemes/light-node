#!/bin/bash

# light-node.sh - Script untuk mengelola dan menjalankan light-node
# Penggunaan: ./light-node.sh [command] [options]

set -e

# Warna untuk output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Direktori default
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
LOG_DIR="$SCRIPT_DIR/logs"
DATA_DIR="$SCRIPT_DIR/data"

# Pastikan direktori yang diperlukan ada
mkdir -p "$CONFIG_DIR" "$LOG_DIR" "$DATA_DIR"

# Function untuk menampilkan banner
show_banner() {
    echo -e "${BLUE}"
    echo "┌────────────────────────────────────────┐"
    echo "│                                        │"
    echo "│        SCAVENGER AIRDROP CLI          │"
    echo "│            LIGHT NODE CLI              │"
    echo "│                                        │"
    echo "└────────────────────────────────────────┘"
    echo -e "${NC}"
}

# Function untuk menampilkan bantuan
show_help() {
    echo -e "${GREEN}Scavenger Airdrop - Layer-Edge Light Node Command Line Interface${NC}"
    echo
    echo "Penggunaan: ./light-node.sh [command] [options]"
    echo
    echo "Commands:"
    echo "  install          Menginstall dependensi yang diperlukan"
    echo "  setup            Mengatur node dengan konfigurasi awal"
    echo "  start            Memulai light node"
    echo "  stop             Menghentikan light node yang sedang berjalan"
    echo "  status           Memeriksa status light node"
    echo "  logs             Menampilkan log dari light node"
    echo "  update           Memperbarui light node ke versi terbaru"
    echo "  backup           Membuat backup dari data node"
    echo "  restore [file]   Memulihkan data node dari backup"
    echo "  info             Menampilkan informasi tentang node"
    echo "  help             Menampilkan pesan bantuan ini"
    echo
    echo "Options:"
    echo "  --config [file]  Menggunakan file konfigurasi khusus"
    echo "  --log-level      Mengatur level log (debug, info, warn, error)"
    echo "  --network        Mengatur jaringan (hanya mainnet)"
    echo
    echo "Contoh:"
    echo "  ./light-node.sh install"
    echo "  ./light-node.sh start"
    echo "  ./light-node.sh status"
    echo
}

# Function untuk menginstall dependensi
install_deps() {
    echo -e "${BLUE}Menginstall dependensi untuk Scavenger Airdrop Light Node...${NC}"
    
    # Deteksi sistem operasi
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "Sistem operasi terdeteksi: Linux"
        # Periksa package manager
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y git build-essential curl jq
        elif command -v yum &> /dev/null; then
            sudo yum update -y
            sudo yum install -y git gcc gcc-c++ make curl jq
        else
            echo -e "${RED}Package manager tidak didukung. Silakan install dependensi secara manual.${NC}"
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Sistem operasi terdeteksi: macOS"
        # Periksa jika Homebrew sudah terinstall
        if ! command -v brew &> /dev/null; then
            echo "Menginstall Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew update
        brew install git curl jq
    else
        echo -e "${RED}Sistem operasi tidak didukung.${NC}"
        exit 1
    fi
    
    # Install Node.js jika belum ada
    if ! command -v node &> /dev/null; then
        echo "Menginstall Node.js..."
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
            sudo apt-get install -y nodejs
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install node@18
        fi
    fi
    
    # Periksa jika Git sudah terinstall
    if ! command -v git &> /dev/null; then
        echo -e "${RED}Git tidak ditemukan. Silakan install Git terlebih dahulu.${NC}"
        exit 1
    fi
    
    # Clone repositori jika belum ada
    if [ ! -d "$SCRIPT_DIR/.git" ]; then
        cd "$(dirname "$SCRIPT_DIR")"
        git clone https://github.com/Layer-Edge/light-node.git
        cd light-node
    else
        cd "$SCRIPT_DIR"
    fi
    
    # Install dependensi Node.js
    echo "Menginstall dependensi Node.js..."
    npm install
    
    echo -e "${GREEN}Instalasi selesai!${NC}"
}

# Function untuk setup node
setup_node() {
    local network="mainnet"
    
    echo -e "${BLUE}Menyiapkan light node untuk jaringan ${network}...${NC}"
    
    # Buat file konfigurasi default jika belum ada
    if [ ! -f "$CONFIG_DIR/config.$network.json" ]; then
        cat > "$CONFIG_DIR/config.$network.json" << EOF
{
    "network": "$network",
    "rpc": {
        "http": {
            "enabled": true,
            "port": 8545
        },
        "ws": {
            "enabled": true,
            "port": 8546
        }
    },
    "p2p": {
        "enabled": true,
        "port": 30303,
        "maxPeers": 25
    },
    "sync": {
        "mode": "light"
    },
    "dataDir": "$DATA_DIR/$network"
}
EOF
        echo -e "${GREEN}File konfigurasi untuk $network dibuat.${NC}"
    else
        echo -e "${YELLOW}File konfigurasi untuk $network sudah ada.${NC}"
    fi
    
    # Buat direktori data untuk jaringan tertentu
    mkdir -p "$DATA_DIR/$network"
    
    echo -e "${GREEN}Setup selesai untuk jaringan $network!${NC}"
    echo -e "${YELLOW}Anda dapat mengedit konfigurasi di: $CONFIG_DIR/config.$network.json${NC}"
}

# Function untuk memulai node
start_node() {
    local network="mainnet"
    local config_file="$CONFIG_DIR/config.$network.json"
    local log_file="$LOG_DIR/node.$network.log"
    
    echo -e "${BLUE}Memulai light node pada jaringan $network...${NC}"
    
    # Periksa jika konfigurasi ada
    if [ ! -f "$config_file" ]; then
        echo -e "${YELLOW}Konfigurasi untuk $network tidak ditemukan. Membuat konfigurasi default...${NC}"
        setup_node
    fi
    
    # Periksa jika node sudah berjalan
    if pgrep -f "node start --config $config_file" > /dev/null; then
        echo -e "${YELLOW}Light node untuk $network sudah berjalan.${NC}"
        return 0
    fi
    
    # Mulai node dengan nohup agar tetap berjalan di latar belakang
    echo -e "${GREEN}Memulai light node dalam mode background...${NC}"
    nohup node "$SCRIPT_DIR/src/index.js" start --config "$config_file" > "$log_file" 2>&1 &
    
    # Simpan PID untuk referensi nanti
    local pid=$!
    echo $pid > "$DATA_DIR/$network.pid"
    
    # Tunggu sebentar dan periksa jika proses masih berjalan
    sleep 2
    if ps -p $pid > /dev/null; then
        echo -e "${GREEN}Light node berhasil dimulai dengan PID: $pid${NC}"
        echo -e "${GREEN}Log tersedia di: $log_file${NC}"
    else
        echo -e "${RED}Gagal memulai light node. Periksa log untuk detail: $log_file${NC}"
        exit 1
    fi
}

# Function untuk menghentikan node
stop_node() {
    local network="mainnet"
    local pid_file="$DATA_DIR/$network.pid"
    
    echo -e "${BLUE}Menghentikan light node untuk jaringan $network...${NC}"
    
    # Periksa jika PID file ada
    if [ ! -f "$pid_file" ]; then
        echo -e "${YELLOW}Light node untuk $network tidak ditemukan atau tidak berjalan.${NC}"
        return 0
    fi
    
    # Ambil PID dan hentikan proses
    local pid=$(cat "$pid_file")
    if ps -p $pid > /dev/null; then
        echo -e "${GREEN}Menghentikan proses dengan PID: $pid${NC}"
        kill $pid
        # Tunggu proses berhenti
        for i in {1..10}; do
            if ! ps -p $pid > /dev/null; then
                break
            fi
            sleep 1
        done
        
        # Periksa jika proses masih berjalan dan paksa berhenti jika perlu
        if ps -p $pid > /dev/null; then
            echo -e "${YELLOW}Proses tidak merespons, memaksa berhenti...${NC}"
            kill -9 $pid
        fi
        
        echo -e "${GREEN}Light node untuk $network berhasil dihentikan.${NC}"
    else
        echo -e "${YELLOW}Proses dengan PID $pid tidak ditemukan.${NC}"
    fi
    
    # Hapus file PID
    rm -f "$pid_file"
}

# Function untuk memeriksa status node
check_status() {
    local network="mainnet"
    local pid_file="$DATA_DIR/$network.pid"
    
    echo -e "${BLUE}Memeriksa status light node untuk jaringan $network...${NC}"
    
    # Periksa jika PID file ada
    if [ ! -f "$pid_file" ]; then
        echo -e "${YELLOW}Light node untuk $network tidak berjalan.${NC}"
        return 0
    fi
    
    # Ambil PID dan periksa status
    local pid=$(cat "$pid_file")
    if ps -p $pid > /dev/null; then
        # Dapatkan info lebih lanjut tentang proses
        local uptime=$(ps -p $pid -o etime= | xargs)
        local cpu=$(ps -p $pid -o %cpu= | xargs)
        local mem=$(ps -p $pid -o %mem= | xargs)
        
        echo -e "${GREEN}Light node untuk $network sedang berjalan:${NC}"
        echo -e "  PID:         ${pid}"
        echo -e "  Uptime:      ${uptime}"
        echo -e "  CPU Usage:   ${cpu}%"
        echo -e "  Memory:      ${mem}%"
        echo -e "  Log File:    $LOG_DIR/node.$network.log"
        echo -e "  Config File: $CONFIG_DIR/config.$network.json"
        echo -e "  Data Dir:    $DATA_DIR/$network"
    else
        echo -e "${YELLOW}PID file ada, tetapi proses dengan PID $pid tidak ditemukan.${NC}"
        echo -e "${YELLOW}Menghapus PID file yang sudah tidak valid...${NC}"
        rm -f "$pid_file"
    fi
}

# Function untuk menampilkan log
show_logs() {
    local network="mainnet"
    local log_file="$LOG_DIR/node.$network.log"
    local lines=${1:-100}
    
    echo -e "${BLUE}Menampilkan $lines baris terakhir dari log untuk jaringan $network...${NC}"
    
    # Periksa jika log file ada
    if [ ! -f "$log_file" ]; then
        echo -e "${YELLOW}File log untuk $network tidak ditemukan.${NC}"
        return 0
    fi
    
    # Tampilkan log
    tail -n $lines "$log_file"
    
    # Tawaran untuk melihat log secara real-time
    echo
    echo -e "${GREEN}Untuk melihat log secara real-time, gunakan: tail -f $log_file${NC}"
}

# Function untuk memperbarui node
update_node() {
    echo -e "${BLUE}Memperbarui light node ke versi terbaru...${NC}"
    
    # Simpan direktori saat ini
    local current_dir=$(pwd)
    
    # Pindah ke direktori script
    cd "$SCRIPT_DIR"
    
    # Periksa jika ini adalah repositori git
    if [ ! -d ".git" ]; then
        echo -e "${RED}Direktori ini bukan repositori git. Tidak dapat memperbarui.${NC}"
        cd "$current_dir"
        exit 1
    fi
    
    # Simpan perubahan lokal jika ada
    if [ -n "$(git status --porcelain)" ]; then
        echo -e "${YELLOW}Perubahan lokal terdeteksi. Menyimpan perubahan...${NC}"
        git stash
    fi
    
    # Perbarui dari repositori
    echo "Mengambil perubahan terbaru dari repositori..."
    git fetch origin
    
    # Perbarui ke versi terbaru
    echo "Memperbarui ke versi terbaru..."
    git pull origin main
    
    # Perbarui dependensi
    echo "Memperbarui dependensi..."
    npm install
    
    echo -e "${GREEN}Light node berhasil diperbarui ke versi terbaru!${NC}"
    
    # Kembalikan ke direktori sebelumnya
    cd "$current_dir"
}

# Function untuk membuat backup
backup_node() {
    local network="mainnet"
    local backup_dir="$SCRIPT_DIR/backups"
    local date_stamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="$backup_dir/backup_${network}_${date_stamp}.tar.gz"
    
    echo -e "${BLUE}Membuat backup data node untuk jaringan $network...${NC}"
    
    # Pastikan direktori backup ada
    mkdir -p "$backup_dir"
    
    # Periksa jika direktori data ada
    if [ ! -d "$DATA_DIR/$network" ]; then
        echo -e "${YELLOW}Direktori data untuk $network tidak ditemukan.${NC}"
        return 0
    fi
    
    # Periksa jika node sedang berjalan
    if [ -f "$DATA_DIR/$network.pid" ]; then
        echo -e "${YELLOW}Node sedang berjalan. Disarankan untuk menghentikan node sebelum backup.${NC}"
        read -p "Lanjutkan backup? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Backup dibatalkan.${NC}"
            return 0
        fi
    fi
    
    # Buat backup
    echo "Membuat backup data..."
    tar -czf "$backup_file" -C "$DATA_DIR" "$network" "$CONFIG_DIR/config.$network.json"
    
    # Periksa jika backup berhasil
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Backup berhasil dibuat: $backup_file${NC}"
        ls -lh "$backup_file"
    else
        echo -e "${RED}Gagal membuat backup.${NC}"
        exit 1
    fi
}

# Function untuk memulihkan backup
restore_backup() {
    local backup_file=$1
    
    if [ -z "$backup_file" ]; then
        echo -e "${RED}File backup tidak ditentukan.${NC}"
        echo -e "${YELLOW}Penggunaan: ./light-node.sh restore [file]${NC}"
        return 1
    fi
    
    # Periksa jika file backup ada
    if [ ! -f "$backup_file" ]; then
        echo -e "${RED}File backup tidak ditemukan: $backup_file${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Memulihkan data dari backup: $backup_file...${NC}"
    
    # Ekstrak network dari nama file backup
    local network="mainnet"
    
    # Periksa jika node sedang berjalan
    if [ -f "$DATA_DIR/$network.pid" ]; then
        echo -e "${YELLOW}Node untuk $network sedang berjalan. Menghentikan node...${NC}"
        stop_node
    fi
    
    # Buat direktori temporer untuk ekstraksi
    local temp_dir=$(mktemp -d)
    
    # Ekstrak backup
    echo "Mengekstrak backup..."
    tar -xzf "$backup_file" -C "$temp_dir"
    
    # Pindahkan data yang diekstrak ke lokasi yang sesuai
    echo "Memulihkan data..."
    if [ -d "$temp_dir/$network" ]; then
        # Backup data yang ada jika perlu
        if [ -d "$DATA_DIR/$network" ]; then
            local date_stamp=$(date +"%Y%m%d_%H%M%S")
            mv "$DATA_DIR/$network" "$DATA_DIR/${network}_backup_${date_stamp}"
            echo -e "${YELLOW}Data yang ada dipindahkan ke: $DATA_DIR/${network}_backup_${date_stamp}${NC}"
        fi
        
        # Pindahkan data yang dipulihkan
        mv "$temp_dir/$network" "$DATA_DIR/"
        
        # Pulihkan konfigurasi jika ada
        if [ -f "$temp_dir/config.$network.json" ]; then
            mv "$temp_dir/config.$network.json" "$CONFIG_DIR/"
        fi
        
        echo -e "${GREEN}Data berhasil dipulihkan untuk jaringan $network!${NC}"
    else
        echo -e "${RED}Direktori data tidak ditemukan dalam backup.${NC}"
        exit 1
    fi
    
    # Bersihkan direktori temporer
    rm -rf "$temp_dir"
}

# Function untuk menampilkan info node
show_info() {
    echo -e "${BLUE}Informasi Scavenger Airdrop Light Node${NC}"
    echo
    
    # Informasi sistem
    echo -e "${GREEN}Informasi Sistem:${NC}"
    echo -e "  OS:           $(uname -s)"
    echo -e "  Kernel:       $(uname -r)"
    echo -e "  Architecture: $(uname -m)"
    if command -v node &> /dev/null; then
        echo -e "  Node.js:      $(node -v)"
        echo -e "  npm:          $(npm -v)"
    else
        echo -e "  Node.js:      ${RED}Tidak ditemukan${NC}"
    fi
    echo
    
    # Informasi direktori
    echo -e "${GREEN}Direktori:${NC}"
    echo -e "  Script:       $SCRIPT_DIR"
    echo -e "  Config:       $CONFIG_DIR"
    echo -e "  Logs:         $LOG_DIR"
    echo -e "  Data:         $DATA_DIR"
    echo
    
    # Informasi jaringan
    echo -e "${GREEN}Jaringan:${NC}"
    local network="mainnet"
            
    # Periksa status
    local status="Tidak berjalan"
    if [ -f "$DATA_DIR/$network.pid" ]; then
        local pid=$(cat "$DATA_DIR/$network.pid")
        if ps -p $pid > /dev/null; then
            status="Berjalan (PID: $pid)"
        else
            status="Mati (PID file ada tetapi proses tidak ditemukan)"
        fi
    fi
    
    echo -e "  $network: $status"
    echo
    
    # Informasi port
    echo -e "${GREEN}Port yang Digunakan:${NC}"
    if [ -f "$CONFIG_DIR/config.$network.json" ]; then
        local http_port=$(grep -oP '"port":\s*\K\d+' "$CONFIG_DIR/config.$network.json" | head -1)
        local ws_port=$(grep -oP '"port":\s*\K\d+' "$CONFIG_DIR/config.$network.json" | tail -1)
        local p2p_port=$(grep -oP '"port":\s*\K\d+' "$CONFIG_DIR/config.$network.json" | tail -2 | head -1)
        
        echo -e "  $network:"
        [ ! -z "$http_port" ] && echo -e "    HTTP RPC:  $http_port"
        [ ! -z "$ws_port" ] && echo -e "    WebSocket: $ws_port"
        [ ! -z "$p2p_port" ] && echo -e "    P2P:       $p2p_port"
    fi
}

# Parse command line arguments
if [ $# -eq 0 ]; then
    show_banner
    show_help
    exit 0
fi

# Command utama
COMMAND=$1
shift

# Parse opsi - Hanya gunakan mainnet
NETWORK="mainnet"

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --network)
            # Abaikan opsi jaringan lain, selalu gunakan mainnet
            echo -e "${YELLOW}Info: Hanya jaringan mainnet yang didukung untuk Scavenger Airdrop${NC}"
            shift
            shift
            ;;
        --config)
            CONFIG_FILE="$2"
            shift
            shift
            ;;
        --log-level)
            LOG_LEVEL="$2"
            shift
            shift
            ;;
        *)
            # Parameter yang tidak dikenal
            echo -e "${RED}Parameter tidak dikenal: $1${NC}"
            exit 1
            ;;
    esac
done

# Eksekusi command
show_banner

case $COMMAND in
    install)
        install_deps
        ;;
    setup)
        setup_node
        ;;
    start)
        start_node
        ;;
    stop)
        stop_node
        ;;
    status)
        check_status
        ;;
    logs)
        show_logs
        ;;
    update)
        update_node
        ;;
    backup)
        backup_node
        ;;
    restore)
        restore_backup "$1"
        ;;
    info)
        show_info
        ;;
    help)
        show_help
        ;;
    *)
        echo -e "${RED}Command tidak dikenal: $COMMAND${NC}"
        show_help
        exit 1
        ;;
esac

exit 0