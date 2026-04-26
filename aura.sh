#!/bin/bash

# Nama file: aura.sh
# Cara pakai: ./aura.sh

# Konfigurasi default
ALERT_TEXT="You are using the FREE version with limited"
PID_FILE="app.pid"
MONITOR_PID_FILE="monitor.pid"
RESTART_COUNT=0
MAX_RESTARTS=100
COMMAND=""
CURRENT_TYPE=""
CURRENT_URL=""
LOG_FILE="app_output.log"
DISPLAY_PID=""
LICENSE_FILE=".license"
DEVICE_ID_FILE=".device_id"
SESSION_FILE=".session"

# GitHub Keys Database
KEYS_URL="https://raw.githubusercontent.com/RasZRengokai/Keys/refs/heads/main/keys.txt"

# Colors - Palet Warna Estetik
BG='\033[48;5;234m'
RED='\033[38;5;203m'
GREEN='\033[38;5;120m'
YELLOW='\033[38;5;228m'
BLUE='\033[38;5;111m'
CYAN='\033[38;5;123m'
PURPLE='\033[38;5;183m'
PINK='\033[38;5;213m'
WHITE='\033[38;5;255m'
GRAY='\033[38;5;246m'
DARK='\033[38;5;238m'
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

echo $$ > "$MONITOR_PID_FILE"

# =============================================
# FUNGSI GAMBAR GARIS DEKORATIF
# =============================================
line_top()    { echo -e "  ${DARK}.${NC}${DARK}-------------------------------------------------${NC}${DARK}.${NC}"; }
line_mid()    { echo -e "  ${DARK}|${NC}${DARK}-------------------------------------------------${NC}${DARK}|${NC}"; }
line_bot()    { echo -e "  ${DARK}'${NC}${DARK}-------------------------------------------------${NC}${DARK}'${NC}"; }
line_empty()  { echo -e "  ${DARK}|${NC}                                                 ${DARK}|${NC}"; }

# =============================================
# BANNER UTAMA
# =============================================
show_banner() {
    clear
    echo ""
    echo -e "  ${DARK}.${NC}${DARK}-------------------------------------------------${NC}${DARK}.${NC}"
    echo -e "  ${DARK}|${NC}                                                 ${DARK}|${NC}"
    echo -e "  ${DARK}|${NC}      ${PINK}   █████╗ ${NC} ${WHITE}██╗   ██╗${NC} ${PURPLE}██████╗ ${NC}  ${PINK}█████╗${NC}      ${DARK}|${NC}"
    echo -e "  ${DARK}|${NC}      ${PINK}  ██╔══██╗${NC} ${WHITE}██║   ██║${NC} ${PURPLE}██╔══██╗${NC} ${PINK}██╔══██╗${NC}     ${DARK}|${NC}"
    echo -e "  ${DARK}|${NC}      ${PINK}  ███████║${NC} ${WHITE}██║   ██║${NC} ${PURPLE}██████╔╝${NC} ${PINK}███████║${NC}     ${DARK}|${NC}"
    echo -e "  ${DARK}|${NC}      ${PINK}  ██╔══██║${NC} ${WHITE}██║   ██║${NC} ${PURPLE}██╔══██╗${NC} ${PINK}██╔══██║${NC}     ${DARK}|${NC}"
    echo -e "  ${DARK}|${NC}      ${PINK}  ██║  ██║${NC} ${WHITE}╚██████╔╝${NC} ${PURPLE}██║  ██║${NC} ${PINK}██║  ██║${NC}     ${DARK}|${NC}"
    echo -e "  ${DARK}|${NC}      ${PINK}  ╚═╝  ╚═╝${NC} ${WHITE} ╚═════╝ ${NC} ${PURPLE}╚═╝  ╚═╝${NC} ${PINK}╚═╝  ╚═╝${NC}     ${DARK}|${NC}"
    echo -e "  ${DARK}|${NC}                                                 ${DARK}|${NC}"
    echo -e "  ${DARK}|${NC}${DARK}-------------------------------------------------${NC}${DARK}|${NC}"
    echo -e "  ${DARK}|${NC}              ${GRAY}${DIM}crafted by @FuumaXyz${NC}               ${DARK}|${NC}"
    echo -e "  ${DARK}'${NC}${DARK}-------------------------------------------------${NC}${DARK}'${NC}"
    echo ""
}

# =============================================
# GENERATE DEVICE ID (FIXED)
# =============================================
generate_device_id() {
    # Generate unique device ID based on hardware + OS info
    local device_info=""
    
    # Get hardware info (aman dibaca)
    if [ -f /etc/machine-id ]; then
        device_info+=$(cat /etc/machine-id 2>/dev/null)
    elif [ -f /var/lib/dbus/machine-id ]; then
        device_info+=$(cat /var/lib/dbus/machine-id 2>/dev/null)
    fi
    
    # Get MAC address - dengan error handling yang lebih baik
    # Coba ip command dulu (lebih modern)
    if command -v ip &>/dev/null; then
        local mac=$(ip link show 2>/dev/null | grep -o -E 'link/ether ([[:xdigit:]]{2}:){5}[[:xdigit:]]{2}' | head -1 | awk '{print $2}')
        if [ -n "$mac" ]; then
            device_info+="$mac"
        fi
    elif command -v ifconfig &>/dev/null; then
        # Redirect stderr ke null untuk menghilangkan warning
        local mac=$(ifconfig 2>/dev/null | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}' | head -1)
        if [ -n "$mac" ]; then
            device_info+="$mac"
        fi
    fi
    
    # Get hostname (selalu aman)
    device_info+=$(hostname 2>/dev/null)
    
    # Get kernel version (selalu aman)
    device_info+=$(uname -a 2>/dev/null)
    
    # Get CPU info (biasanya aman dibaca)
    if [ -f /proc/cpuinfo ]; then
        device_info+=$(grep -m1 "Serial" /proc/cpuinfo 2>/dev/null)
        device_info+=$(grep -m1 "Hardware" /proc/cpuinfo 2>/dev/null)
    fi
    
    # Fallback jika semua info kosong
    if [ -z "$device_info" ]; then
        device_info=$(date +%s)${RANDOM}${RANDOM}$(hostname)
    fi
    
    # Hash the combined info
    echo "$device_info" | md5sum | cut -d' ' -f1
}

# =============================================
# CHECK LICENSE SYSTEM
# =============================================
check_license() {
    # Jika sudah ada session valid
    if [ -f "$SESSION_FILE" ]; then
        local saved_key=$(cat "$SESSION_FILE" | grep "KEY:" | cut -d':' -f2)
        local saved_device=$(cat "$SESSION_FILE" | grep "DEVICE:" | cut -d':' -f2)
        local current_device=$(generate_device_id)
        
        if [ "$saved_device" = "$current_device" ]; then
            # Verifikasi key masih valid
            if verify_key_online "$saved_key" "$current_device"; then
                return 0
            fi
        else
            # Device berbeda, hapus session
            echo -e "  ${YELLOW}[!] Device changed! Please login again.${NC}"
            rm -f "$SESSION_FILE" "$DEVICE_ID_FILE"
            sleep 2
        fi
    fi
    
    # Login required
    login_menu
    
    if [ $? -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# =============================================
# VERIFY KEY ONLINE (FIXED)
# =============================================
verify_key_online() {
    local key="$1"
    local device_id="$2"
    
    # Download keys database
    local temp_keys=$(mktemp)
    if ! curl -s -L "$KEYS_URL" -o "$temp_keys" 2>/dev/null; then
        echo -e "  ${RED}[!] Cannot connect to license server${NC}"
        rm -f "$temp_keys"
        return 1
    fi
    
    # Debug: Tampilkan isi database (bisa dihapus nanti)
    # echo "DEBUG: Downloaded keys:"
    # cat "$temp_keys"
    # echo "DEBUG: Looking for key: $key"
    # echo "DEBUG: Current device: $device_id"
    
    # Cari key di database - PASTIKAN EXACT MATCH dengan ^ dan |
    local found_line=$(grep "^${key}|" "$temp_keys")
    
    if [ -z "$found_line" ]; then
        # Debug
        # echo "DEBUG: Key not found in database"
        rm -f "$temp_keys"
        return 1
    fi
    
    # Debug
    # echo "DEBUG: Found line: $found_line"
    
    # FIX: Parse format KEY|STATUS|DEVICE_ID|EXPIRY|PLAN dengan benar
    # Gunakan IFS dan read untuk parsing yang akurat
    local db_key db_status db_device db_expiry db_plan
    IFS='|' read -r db_key db_status db_device db_expiry db_plan <<< "$found_line"
    
    # Debug
    # echo "DEBUG: Parsed -> Key:$db_key Status:$db_status Device:$db_device Expiry:$db_expiry Plan:$db_plan"
    
    # Check status
    if [ "$db_status" = "INACTIVE" ] || [ "$db_status" = "BANNED" ]; then
        rm -f "$temp_keys"
        case "$db_status" in
            "INACTIVE") echo -e "  ${RED}[!] License is inactive${NC}" ;;
            "BANNED") echo -e "  ${RED}[!] License is banned${NC}" ;;
        esac
        return 1
    fi
    
    # Check expiry
    if [ "$db_expiry" != "NEVER" ]; then
        local current_timestamp=$(date +%s)
        local expiry_timestamp=$(date -d "$db_expiry" +%s 2>/dev/null)
        if [ $? -eq 0 ] && [ $current_timestamp -gt $expiry_timestamp ]; then
            rm -f "$temp_keys"
            echo -e "  ${RED}[!] License expired on $db_expiry${NC}"
            return 1
        fi
    fi
    
    # FIX: Check device lock dengan logic yang benar
    if [ "$db_device" = "ANY" ]; then
        # Key belum terikat device apapun
        # Cek apakah device ini sudah punya key lain
        local device_exists=$(grep "|${device_id}|" "$temp_keys")
        if [ -n "$device_exists" ]; then
            local existing_key=$(echo "$device_exists" | cut -d'|' -f1)
            if [ "$existing_key" != "$key" ]; then
                # Device ini sudah terdaftar dengan key lain
                rm -f "$temp_keys"
                echo -e "${RED}\n  [!] This device already has another license"
                echo -e "  ${YELLOW}[!] One device can only use one license${NC}"
                return 1
            fi
        fi
        
        # First time login - auto bind device (hanya catat di lokal)
        echo -e "  ${YELLOW}[!] First login detected - Binding device...${NC}"
        # Simpan binding info
        echo "$found_line" > "$DEVICE_ID_FILE"
        rm -f "$temp_keys"
        return 0
        
    elif [ "$db_device" = "$device_id" ]; then
        # Device ID cocok - key ini untuk device ini
        rm -f "$temp_keys"
        return 0
        
    else
        # Device ID berbeda
        rm -f "$temp_keys"
        echo -e "  ${RED}[!] License already used on another device${NC}"
        echo -e "  ${GRAY}Your Device ID    : ${device_id:0:16}...${NC}"
        echo -e "  ${GRAY}Registered Device : ${db_device:0:16}...${NC}"
        return 1
    fi
    
    rm -f "$temp_keys"
    return 0
}

# =============================================
# LOGIN MENU
# =============================================
login_menu() {
    local attempts=0
    local max_attempts=3
    local current_device_id=$(generate_device_id)
    
    while [ $attempts -lt $max_attempts ]; do
        clear
        echo ""
        echo -e "  ${DARK}.${NC}${DARK}-------------------------------------------------${NC}${DARK}.${NC}"
        echo -e "  ${DARK}|${NC}                                                 ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}             ${WHITE}${BOLD}[ LICENSE VERIFICATION ]${NC}            ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}                                                 ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}${DARK}-------------------------------------------------${NC}${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}                                                 ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}   ${WHITE}${BOLD}YOUR DEVICE ID:${NC}                               ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}   ${CYAN}${current_device_id}${NC}"
        echo -e "  ${DARK}|${NC}                                                 ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}${DARK}-------------------------------------------------${NC}${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}                                                 ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}   ${GRAY}Send this ID to admin to get license key${NC}      ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}   ${GRAY}Then enter the license key below${NC}              ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}                                                 ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}   ${RED}Attempts: ${WHITE}$attempts${GRAY}/${WHITE}$max_attempts${NC}         "
        echo -e "  ${DARK}|${NC}                                                 ${DARK}|${NC}"
        echo -e "  ${DARK}'${NC}${DARK}-------------------------------------------------${NC}${DARK}'${NC}"
        echo ""
        echo -ne "  ${CYAN}[?] License Key${NC} ${DARK}:${NC} "
        read license_key
        echo ""
        
        if [ -z "$license_key" ]; then
            echo -e "  ${RED}[!] Key cannot be empty!${NC}"
            sleep 1
            ((attempts++))
            continue
        fi
        
        # Loading animation
        echo -ne "  ${YELLOW}[*] Verifying key...${NC}"
        sleep 0.5
        echo -ne "\r  ${YELLOW}[*] Checking database...${NC}"
        sleep 0.5
        echo -ne "\r  ${YELLOW}[*] Validating device...${NC}"
        sleep 0.5
        
        if verify_key_online "$license_key" "$current_device_id"; then
            echo -e "\r  ${GREEN}[OK] License verified successfully!     ${NC}"
            
            # Save session
            echo "KEY:$license_key" > "$SESSION_FILE"
            echo "DEVICE:$current_device_id" >> "$SESSION_FILE"
            echo "LOGIN_TIME:$(date '+%Y-%m-%d %H:%M:%S')" >> "$SESSION_FILE"
            
            # Save license locally
            echo "$license_key" > "$LICENSE_FILE"
            echo "$current_device_id" > "$DEVICE_ID_FILE"
            
            echo ""
            echo -e "  ${GREEN}╔═══════════════════════════════════════════════╗${NC}"
            echo -e "  ${GREEN}║${NC}                                               ${GREEN}║${NC}"
            echo -e "  ${GREEN}║${NC}   ${WHITE}${BOLD}✅ ACCESS GRANTED${NC}                           ${GREEN}║${NC}"
            echo -e "  ${GREEN}║${NC}                                               ${GREEN}║${NC}"
            echo -e "  ${GREEN}║${NC}   ${GRAY}Device locked & verified successfully${NC}       ${GREEN}║${NC}"
            echo -e "  ${GREEN}║${NC}   ${GRAY}Welcome back!${NC}                               ${GREEN}║${NC}"
            echo -e "  ${GREEN}║${NC}                                               ${GREEN}║${NC}"
            echo -e "  ${GREEN}╚═══════════════════════════════════════════════╝${NC}"
            sleep 3
            return 0
        else
            echo -e "\r  ${RED}[!] Verification failed!                    ${NC}"
            echo ""
            echo -e "  ${YELLOW}Possible reasons:${NC}"
            echo -e "  ${GRAY}• Invalid license key${NC}"
            echo -e "  ${GRAY}• License already bound to another device${NC}"
            echo -e "  ${GRAY}• License expired${NC}"
            echo -e "  ${GRAY}• License inactive/banned${NC}"
            echo -e "  ${GRAY}• This device already has another license${NC}"
            echo ""
            echo -e "  ${YELLOW}Your Device ID: ${CYAN}${current_device_id}${NC}"
            echo -e "  ${YELLOW}Send this to admin if you need new license${NC}"
            echo ""
            echo -ne "  ${GRAY}Press Enter to try again...${NC}"
            read
            ((attempts++))
        fi
    done
    
    echo ""
    echo -e "  ${RED}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "  ${RED}║${NC}                                               ${RED}║${NC}"
    echo -e "  ${RED}║${NC}   ${WHITE}${BOLD}⛔ ACCESS DENIED${NC}                            ${RED}║${NC}"
    echo -e "  ${RED}║${NC}                                               ${RED}║${NC}"
    echo -e "  ${RED}║${NC}   ${GRAY}Maximum login attempts reached${NC}              ${RED}║${NC}"
    echo -e "  ${RED}║${NC}   ${GRAY}Device ID: ${current_device_id:0:16}...${NC}              ${RED}║${NC}"
    echo -e "  ${RED}║${NC}                                               ${RED}║${NC}"
    echo -e "  ${RED}╚═══════════════════════════════════════════════╝${NC}"
    rm -f "$SESSION_FILE" "$LICENSE_FILE" "$DEVICE_ID_FILE"
    sleep 3
    return 1
}

# =============================================
# CHECK NODE MODULES
# =============================================
check_node_modules() {
    echo -e "  ${GRAY}[*] Checking modules...${NC}"
    
    if [ -d "./node_modules" ]; then
        echo -e "    ${GREEN}[OK]${NC} ${GRAY}node_modules ready${NC}"
        return 0
    fi
    
    if [ -f "./node_modules.zip" ]; then
        echo -e "    ${GRAY}--> Extracting node_modules.zip...${NC}"
        
        if ! command -v unzip &> /dev/null; then
            echo -e "  ${RED}ERROR: 'unzip' not found!${NC}"
            exit 1
        fi
        
        if unzip -q node_modules.zip -d ./ 2>&1; then
            echo -e "    ${GREEN}[OK]${NC} ${GRAY}Extraction complete${NC}"
        else
            echo -e "  ${RED}ERROR: Extraction failed!${NC}"
            exit 1
        fi
    else
        echo -e "  ${RED}ERROR: node_modules not found!${NC}"
        exit 1
    fi
}

# =============================================
# MENU UTAMA
# =============================================
main_menu() {
    while true; do
        show_banner
        echo -e "  ${DARK}.${NC}${DARK}-------------------------------------------------${NC}${DARK}.${NC}"
        echo -e "  ${DARK}|${NC}                                                 ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}                  ${WHITE}${BOLD}[ MAIN MENU ]${NC}                  ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}                                                 ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}${DARK}-------------------------------------------------${NC}${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}                                                 ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}   ${GREEN}[1]${NC}  ${WHITE}Views${NC}            ${GRAY}${DIM}-- Boost Views${NC}          ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}   ${GREEN}[2]${NC}  ${WHITE}Hearts${NC}           ${GRAY}${DIM}-- Boost Hearts${NC}         ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}   ${GREEN}[3]${NC}  ${WHITE}Favorites${NC}        ${GRAY}${DIM}-- Boost Favorites${NC}      ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}                                                 ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}${DARK}-------------------------------------------------${NC}${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}                                                 ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}   ${BLUE}[4]${NC}  ${GRAY}Settings${NC}                                 ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}   ${PURPLE}[5]${NC}  ${GRAY}License Info${NC}                             ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}   ${RED}[6]${NC}  ${GRAY}Logout & Exit${NC}                            ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}                                                 ${DARK}|${NC}"
        echo -e "  ${DARK}'${NC}${DARK}-------------------------------------------------${NC}${DARK}'${NC}"
        echo ""
        echo -ne "  ${PINK}>>${NC} ${WHITE}Select${NC} ${GRAY}[1-6]${NC} ${DARK}:${NC} "
        read menu_choice

        case $menu_choice in
            1) push_menu "Up Views" ;;
            2) push_menu "Up Hearts" ;;
            3) push_menu "Up Favorites" ;;
            4) settings_menu ;;
            5) show_license_info ;;
            6)
                echo -e "\n  ${YELLOW}[!] Logging out...${NC}"
                rm -f "$SESSION_FILE" "$LICENSE_FILE" "$DEVICE_ID_FILE"
                echo -e "  ${GREEN}[OK] Session cleared${NC}"
                echo -e "  ${GRAY}Goodbye!${NC}\n"
                cleanup_all
                exit 0
                ;;
            *)
                echo -e "  ${RED}[!] Invalid choice${NC}"
                sleep 1
                ;;
        esac
    done
}

# =============================================
# SHOW LICENSE INFO
# =============================================
show_license_info() {
    clear
    
    local current_device_id=""
    if [ -f "$DEVICE_ID_FILE" ]; then
        current_device_id=$(cat "$DEVICE_ID_FILE")
    else
        current_device_id=$(generate_device_id)
    fi
    
    echo ""
    line_top
    line_empty
    echo -e "  ${DARK}|${NC}             ${WHITE}${BOLD}[ LICENSE INFORMATION ]${NC}             ${DARK}|${NC}"
    line_empty
    line_mid
    line_empty
    
    if [ -f "$SESSION_FILE" ]; then
        local key=$(cat "$SESSION_FILE" | grep "KEY:" | cut -d':' -f2)
        local device=$(cat "$SESSION_FILE" | grep "DEVICE:" | cut -d':' -f2)
        local login_time=$(cat "$SESSION_FILE" | grep "LOGIN_TIME:" | cut -d':' -f2-)
        
        echo -e "  ${DARK}|${NC}   ${WHITE}License Key${NC} ${DARK}:${NC} ${GREEN}${key}${NC}"
        echo -e "  ${DARK}|${NC}   ${WHITE}Device ID${NC}   ${DARK}:${NC} ${CYAN}${device}${NC}"
        echo -e "  ${DARK}|${NC}   ${WHITE}Login At${NC}    ${DARK}:${NC} ${GRAY}${login_time}${NC}"
        echo -e "  ${DARK}|${NC}   ${WHITE}Status${NC}      ${DARK}:${NC} ${GREEN}${BOLD}● ACTIVE${NC}"
        
        # Check expiry
        local temp_keys=$(mktemp)
        if curl -s -L "$KEYS_URL" -o "$temp_keys" 2>/dev/null; then
            local found_line=$(grep "^${key}|" "$temp_keys")
            if [ -n "$found_line" ]; then
                IFS='|' read -r dummy dummy dummy db_expiry db_plan <<< "$found_line"
                echo -e "  ${DARK}|${NC}   ${WHITE}Plan${NC}        ${DARK}:${NC} ${PURPLE}${db_plan}${NC}"
                echo -e "  ${DARK}|${NC}   ${WHITE}Expiry${NC}      ${DARK}:${NC} ${YELLOW}${db_expiry}${NC}"
            fi
        fi
        rm -f "$temp_keys"
    else
        echo -e "  ${DARK}|${NC}   ${RED}No active session found${NC}"
        echo -e "  ${DARK}|${NC}   ${WHITE}Your Device ID${NC} ${DARK}:${NC} ${CYAN}${current_device_id}${NC}"
    fi
    
    line_empty
    line_bot
    echo ""
    echo -e "  ${GRAY}${DIM}To get license, send Device ID to admin${NC}"
    echo ""
    echo -ne "  ${GRAY}Press Enter to continue...${NC}"
    read
}

# [SISA FUNCTIONS TETAP SAMA - push_menu, settings_menu, start_aura, cleanup_all, check_dependencies, dll]
# =============================================
# MENU PUSH
# =============================================
push_menu() {
    local type="$1"
    local url=""
    
    while true; do
        show_banner
        
        local label=""
        case "$type" in
            "Up Views")     label="VIEWS" ;;
            "Up Hearts")    label="HEARTS" ;;
            "Up Favorites") label="FAVORITES" ;;
        esac
        
        echo -e "  ${DARK}.${NC}${DARK}-------------------------------------------------${NC}${DARK}.${NC}"
        echo -e "  ${DARK}|${NC}                                                 ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}                ${WHITE}${BOLD}[ PUSH ${label} ]${NC}    "
        echo -e "  ${DARK}|${NC}                                                 ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}${DARK}-------------------------------------------------${NC}${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}                                                 ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}   ${GREEN}[1]${NC}  ${WHITE}Enter Target URL${NC}                         ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}   ${YELLOW}[2]${NC}  ${GRAY}Back to Menu${NC}                             ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}                                                 ${DARK}|${NC}"
        echo -e "  ${DARK}'${NC}${DARK}-------------------------------------------------${NC}${DARK}'${NC}"
        echo ""
        echo -ne "  ${PINK}>>${NC} ${WHITE}Select${NC} ${GRAY}[1-2]${NC} ${DARK}:${NC} "
        read choice

        case $choice in
            1)
                echo ""
                echo -ne "  ${CYAN}URL${NC} ${DARK}:${NC} "
                read custom_url
                if [ -z "$custom_url" ]; then
                    echo -e "  ${RED}[!] URL cannot be empty!${NC}"
                    sleep 1
                    continue
                fi
                url="$custom_url"
                CURRENT_TYPE="$type"
                CURRENT_URL="$url"
                COMMAND="node bottok.js -t '$type' -l '$url'"
                start_aura
                ;;
            2)
                return
                ;;
            *)
                echo -e "  ${RED}[!] Invalid choice${NC}"
                sleep 1
                ;;
        esac
    done
}

# =============================================
# SETTINGS MENU
# =============================================
settings_menu() {
    while true; do
        show_banner
        echo -e "  ${DARK}.${NC}${DARK}-------------------------------------------------${NC}${DARK}.${NC}"
        echo -e "  ${DARK}|${NC}                                                 ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}                 ${WHITE}${BOLD}[ SETTINGS ]${NC}                    ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}                                                 ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}${DARK}-------------------------------------------------${NC}${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}                                                 ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}   ${RED}[1]${NC}  ${WHITE}Remove Cookies${NC}                           ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}   ${GREEN}[2]${NC}  ${WHITE}Set Cookies${NC}                              ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}   ${BLUE}[3]${NC}  ${WHITE}Extract Modules${NC}                          ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}   ${CYAN}[4]${NC}  ${WHITE}Show Device ID${NC}                           ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}                                                 ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}${DARK}-------------------------------------------------${NC}${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}                                                 ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}   ${YELLOW}[5]${NC}  ${GRAY}Back${NC}                                     ${DARK}|${NC}"
        echo -e "  ${DARK}|${NC}                                                 ${DARK}|${NC}"
        echo -e "  ${DARK}'${NC}${DARK}-------------------------------------------------${NC}${DARK}'${NC}"
        echo ""
        echo -ne "  ${PINK}>>${NC} ${WHITE}Select${NC} ${GRAY}[1-5]${NC} ${DARK}:${NC} "
        read choice

        case $choice in
            1)
                echo ""
                if [ -f "./cookies.json" ]; then
                    rm -f "./cookies.json"
                    echo -e "  ${GREEN}[OK]${NC} ${GRAY}cookies.json removed${NC}"
                fi
                if [ -f "./cookies.txt" ]; then
                    rm -f "./cookies.txt"
                    echo -e "  ${GREEN}[OK]${NC} ${GRAY}cookies.txt removed${NC}"
                fi
                if [ ! -f "./cookies.json" ] && [ ! -f "./cookies.txt" ]; then
                    echo -e "  ${GRAY}No cookies found${NC}"
                fi
                echo ""
                echo -ne "  ${GRAY}Press Enter to continue...${NC}"
                read
                ;;
            2)
                echo ""
                echo -e "  ${YELLOW}Paste your cookies below:${NC}"
                echo -e "  ${GRAY}${DIM}Press Ctrl+D when finished${NC}"
                echo -e "  ${DARK}---------------------------------------------------${NC}"
                
                rm -f "./cookies.json"
                cat > "./cookies.txt"
                
                if [ -f "./cookies.txt" ] && [ -s "./cookies.txt" ]; then
                    echo ""
                    echo -e "  ${GREEN}[OK]${NC} ${GRAY}Cookies saved successfully${NC}"
                else
                    echo -e "  ${RED}[!!]${NC} ${GRAY}Failed to save cookies${NC}"
                fi
                echo ""
                echo -ne "  ${GRAY}Press Enter to continue...${NC}"
                read
                ;;
            3)
                echo ""
                if [ -f "./node_modules.zip" ]; then
                    echo -e "  ${GRAY}--> Removing old modules...${NC}"
                    rm -rf "./node_modules"
                    echo -e "  ${GRAY}--> Extracting node_modules.zip...${NC}"
                    if unzip -q node_modules.zip -d ./ 2>&1; then
                        echo -e "  ${GREEN}[OK]${NC} ${GRAY}Modules extracted successfully${NC}"
                    else
                        echo -e "  ${RED}[!!]${NC} ${GRAY}Extraction failed${NC}"
                    fi
                else
                    echo -e "  ${RED}[!!]${NC} ${GRAY}node_modules.zip not found${NC}"
                fi
                echo ""
                echo -ne "  ${GRAY}Press Enter to continue...${NC}"
                read
                ;;
            4)
                echo ""
                local did=$(generate_device_id)
                echo -e "  ${CYAN}╔═══════════════════════════════════════════════╗${NC}"
                echo -e "  ${CYAN}║${NC}   ${WHITE}${BOLD}YOUR DEVICE ID${NC}                             ${CYAN}║${NC}"
                echo -e "  ${CYAN}║${NC}   ${GREEN}${did}${NC}   ${CYAN}║${NC}"
                echo -e "  ${CYAN}║${NC}                                               ${CYAN}║${NC}"
                echo -e "  ${CYAN}║${NC}   ${GRAY}Send this to admin for license key${NC}          ${CYAN}║${NC}"
                echo -e "  ${CYAN}╚═══════════════════════════════════════════════╝${NC}"
                echo ""
                echo -ne "  ${GRAY}Press Enter to continue...${NC}"
                read
                ;;
            5)
                return
                ;;
            *)
                echo -e "  ${RED}[!] Invalid choice${NC}"
                sleep 1
                ;;
        esac
    done
}

# =============================================
# CLEANUP
# =============================================
cleanup_all() {
    if [ -f "$PID_FILE" ]; then
        APP_PID=$(cat "$PID_FILE")
        if [ -n "$APP_PID" ] && kill -0 "$APP_PID" 2>/dev/null; then
            kill "$APP_PID" 2>/dev/null
            sleep 0.5
            kill -9 "$APP_PID" 2>/dev/null
        fi
        rm -f "$PID_FILE"
    fi
    
    if [ -n "$DISPLAY_PID" ] && kill -0 "$DISPLAY_PID" 2>/dev/null; then
        kill "$DISPLAY_PID" 2>/dev/null
    fi
    
    pkill -f "bottok.js" 2>/dev/null
    pkill -f "node bottok.js" 2>/dev/null
    
    rm -f "$LOG_FILE" "$MONITOR_PID_FILE"
}

# =============================================
# LIVE SESSION
# =============================================
start_aura() {
    RESTART_COUNT=0
    
    clear
    
    case "$CURRENT_TYPE" in
        "Up Views")     TYPE_LABEL="VIEWS" ;;
        "Up Hearts")    TYPE_LABEL="HEARTS" ;;
        "Up Favorites") TYPE_LABEL="FAVORITES" ;;
        *)              TYPE_LABEL="UNKNOWN" ;;
    esac
    
    echo ""
    line_top
    line_empty
    echo -e "  ${DARK}|${NC}               ${WHITE}${BOLD}[ LIVE SESSION ]${NC}                  ${DARK}|${NC}"
    line_empty
    line_mid
    line_empty
    echo -e "  ${DARK}|${NC}   ${WHITE}Type${NC}     ${DARK}:${NC} ${GREEN}${BOLD}${TYPE_LABEL}${NC}"
    echo -e "  ${DARK}|${NC}   ${WHITE}Target${NC}   ${DARK}:${NC} ${CYAN}${CURRENT_URL}${NC}"
    echo -e "  ${DARK}|${NC}   ${WHITE}Session${NC}  ${DARK}:${NC} ${YELLOW}${RESTART_COUNT}${GRAY}/${YELLOW}${MAX_RESTARTS}${NC}"
    echo -e "  ${DARK}|${NC}   ${WHITE}Started${NC}  ${DARK}:${NC} ${GRAY}$(date '+%H:%M:%S')${NC}"
    line_empty
    line_bot
    echo ""
    echo -e "  ${GRAY}${DIM}Press Ctrl+C to stop session${NC}"
    echo -e "  ${DARK}---------------------------------------------------${NC}"
    echo ""
    
    > "$LOG_FILE"
    
    script -q -c "$COMMAND" /dev/null > "$LOG_FILE" 2>&1 &
    APP_PID=$!
    echo "$APP_PID" > "$PID_FILE"
    
    sleep 2
    
    if ! kill -0 "$APP_PID" 2>/dev/null; then
        echo -e "  ${RED}[!] Failed to start session!${NC}"
        echo -ne "  ${GRAY}Press Enter to return...${NC}"
        read
        return 1
    fi
    
    tail -f "$LOG_FILE" 2>/dev/null &
    DISPLAY_PID=$!
    
    local spinner=('|' '/' '-' '\')
    local spin_idx=0
    
    while true; do
        sleep 3
        
        if ! kill -0 "$APP_PID" 2>/dev/null; then
            ((RESTART_COUNT++))
            
            if [ $RESTART_COUNT -gt $MAX_RESTARTS ]; then
                echo ""
                echo -e "  ${RED}.---------------------------------------------------.${NC}"
                echo -e "  ${RED}|${NC}  ${WHITE}[!] Max sessions reached (${MAX_RESTARTS})${NC}               ${RED}|${NC}"
                echo -e "  ${RED}|${NC}  ${WHITE}Session ended.${NC}                                   ${RED}|${NC}"
                echo -e "  ${RED}'---------------------------------------------------'${NC}"
                
                if [ -n "$DISPLAY_PID" ] && kill -0 "$DISPLAY_PID" 2>/dev/null; then
                    kill "$DISPLAY_PID" 2>/dev/null
                    DISPLAY_PID=""
                fi
                rm -f "$PID_FILE"
                
                echo -ne "  ${GRAY}Press Enter to return...${NC}"
                read
                return
            fi
            
            echo ""
            echo -ne "  ${YELLOW}[${spinner[$spin_idx]}]${NC} ${GRAY}Restarting session...${NC}"
            spin_idx=$(( (spin_idx + 1) % 4 ))
            
            sleep 1
            
            if [ -n "$DISPLAY_PID" ] && kill -0 "$DISPLAY_PID" 2>/dev/null; then
                kill "$DISPLAY_PID" 2>/dev/null
                DISPLAY_PID=""
            fi
            
            > "$LOG_FILE"
            
            script -q -c "$COMMAND" /dev/null > "$LOG_FILE" 2>&1 &
            APP_PID=$!
            echo "$APP_PID" > "$PID_FILE"
            
            sleep 2
            
            clear
            echo ""
            line_top
            line_empty
            echo -e "  ${DARK}|${NC}             ${WHITE}${BOLD}[ LIVE SESSION ]${NC}                  ${DARK}|${NC}"
            line_empty
            line_mid
            line_empty
            echo -e "  ${DARK}|${NC}   ${WHITE}Type${NC}     ${DARK}:${NC} ${GREEN}${BOLD}${TYPE_LABEL}${NC}"
            echo -e "  ${DARK}|${NC}   ${WHITE}Target${NC}   ${DARK}:${NC} ${CYAN}${CURRENT_URL}${NC}"
            echo -e "  ${DARK}|${NC}   ${WHITE}Session${NC}  ${DARK}:${NC} ${YELLOW}${RESTART_COUNT}${GRAY}/${YELLOW}${MAX_RESTARTS}${NC}"
            echo -e "  ${DARK}|${NC}   ${WHITE}Updated${NC}  ${DARK}:${NC} ${GRAY}$(date '+%H:%M:%S')${NC}"
            line_empty
            line_bot
            echo ""
            echo -e "  ${GRAY}${DIM}Press Ctrl+C to stop session${NC}"
            echo -e "  ${DARK}---------------------------------------------------${NC}"
            echo ""
            
            tail -f "$LOG_FILE" 2>/dev/null &
            DISPLAY_PID=$!
        fi
    done
}

# =============================================
# CHECK DEPENDENCIES
# =============================================
check_dependencies() {
    clear
    echo ""
    line_top
    line_empty
    echo -e "  ${DARK}|${NC}                 ${WHITE}${BOLD}[ SYSTEM CHECK ]${NC}                ${DARK}|${NC}"
    line_empty
    line_bot
    echo ""
    
    if ! command -v node &> /dev/null; then
        echo -e "  ${RED}[!!]${NC} Node.js   ${DARK}:${NC} ${RED}not found${NC}"
        echo -e "  ${GRAY}     --> Install Node.js first${NC}"
        exit 1
    fi
    echo -e "  ${GREEN}[OK]${NC} Node.js   ${DARK}:${NC} ${GRAY}$(node --version)${NC}"
    
    if ! command -v script &> /dev/null; then
        echo -e "  ${RED}[!!]${NC} script    ${DARK}:${NC} ${RED}not found${NC}"
        exit 1
    fi
    echo -e "  ${GREEN}[OK]${NC} script    ${DARK}:${NC} ${GRAY}ready${NC}"
    
    if ! command -v curl &> /dev/null; then
        echo -e "  ${RED}[!!]${NC} curl      ${DARK}:${NC} ${RED}not found${NC}"
        exit 1
    fi
    echo -e "  ${GREEN}[OK]${NC} curl      ${DARK}:${NC} ${GRAY}ready${NC}"
    
    if ! command -v unzip &> /dev/null; then
        echo -e "  ${YELLOW}[--]${NC} unzip     ${DARK}:${NC} ${GRAY}not found${NC}"
    else
        echo -e "  ${GREEN}[OK]${NC} unzip     ${DARK}:${NC} ${GRAY}ready${NC}"
    fi
    
    if [ ! -f "./bottok.js" ]; then
        echo -e "  ${RED}[!!]${NC} bottok.js ${DARK}:${NC} ${RED}not found${NC}"
        exit 1
    fi
    echo -e "  ${GREEN}[OK]${NC} bottok.js ${DARK}:${NC} ${GRAY}ready${NC}"
    
    echo ""
    check_node_modules
    rm -f "$SESSION_FILE" "$LICENSE_FILE" "$DEVICE_ID_FILE"
    
    echo ""
    echo -e "  ${DARK}---------------------------------------------------${NC}"
    echo -e "  ${GREEN}${BOLD}[ SYSTEM READY ]${NC}"
    echo ""
    sleep 2
}

# =============================================
# SIGNAL HANDLER
# =============================================
trap 'cleanup_all; exit 0' SIGINT SIGTERM EXIT

# =============================================
# MAIN
# =============================================
check_dependencies

# Check license before continuing
if check_license; then
    main_menu
else
    echo -e "\n  ${RED}Exiting...${NC}\n"
    exit 1
fi