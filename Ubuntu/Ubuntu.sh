#!/bin/bash
RED='\033[38;5;196m'
GREEN='\033[38;5;46m'
YELLOW='\033[38;5;226m'
CYAN='\033[38;5;51m'
WHITE='\033[38;5;231m'
BOLD='\033[1m'
NC='\033[0m'
NEON_GREEN='\033[38;5;46m'
NEON_RED='\033[38;5;196m'
NEON_CYAN='\033[38;5;51m'
NEON_PINK='\033[38;5;201m'
NEON_BLUE='\033[38;5;45m'
NEON_YELLOW='\033[38;5;226m'
NEON_MAGENTA='\033[38;5;165m'
NEON_LIME='\033[38;5;118m'
NEON_GOLD='\033[38;5;220m'
NEON_AQUA='\033[38;5;123m'
NEON_LAVENDER='\033[38;5;147m'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIRROR_FILE="${SCRIPT_DIR}/mirror.txt"
DNS_FILE="${SCRIPT_DIR}/dns.txt"
LOG_FILE="/var/log/mirror_optimizer.log"
BACKUP_MIRROR="/etc/apt/sources.list.backup.$(date +%Y%m%d_%H%M%S)"
BACKUP_DNS="/etc/resolv.conf.backup.$(date +%Y%m%d_%H%M%S)"
declare -A MIRROR_SPEEDS
declare -A DNS_LATENCIES
BEST_MIRROR=""
BEST_DNS=""
OS_VERSION=""
OS_CODENAME=""

center_text() {
local text="$1"
local color="$2"
local term_width=$(tput cols 2>/dev/null || echo 80)
local text_len=${#text}
local padding=$(( (term_width - text_len) / 2 ))
if [[ $padding -lt 0 ]]; then
padding=0
fi
printf "${color}%*s%s${NC}\n" "$padding" "" "$text"
}

glitch_text_center() {
local text="$1"
local glitch_color="$2"
local final_color="$3"
local delay="${4:-0.06}"
local term_width=$(tput cols 2>/dev/null || echo 80)
local text_len=${#text}
local padding=$(( (term_width - text_len) / 2 ))
if [[ $padding -lt 0 ]]; then
padding=0
fi
for i in {1..12}; do
local glitched=""
if [[ $((i % 2)) -eq 0 ]]; then
local color="${glitch_color}"
else
if [[ "$glitch_color" == "${NEON_RED}" ]]; then
local color="\033[38;5;160m"
elif [[ "$glitch_color" == "${NEON_CYAN}" ]]; then
local color="\033[38;5;50m"
elif [[ "$glitch_color" == "${NEON_PINK}" ]]; then
local color="\033[38;5;198m"
elif [[ "$glitch_color" == "${NEON_BLUE}" ]]; then
local color="\033[38;5;39m"
elif [[ "$glitch_color" == "${NEON_MAGENTA}" ]]; then
local color="\033[38;5;164m"
elif [[ "$glitch_color" == "${NEON_GREEN}" ]]; then
local color="\033[38;5;82m"
elif [[ "$glitch_color" == "${NEON_YELLOW}" ]]; then
local color="\033[38;5;190m"
else
local color="${glitch_color}"
fi
fi
for ((j=0; j<${#text}; j++)); do
if [[ $((RANDOM % 4)) -eq 0 ]] && [[ "${text:$j:1}" != " " ]]; then
local alt_chars=(
"$" "#" "@" "&" "%" "*" "+" "=" "?" "!" "~"
"Ҝ" "Ŧ" "Đ" "Å" "Ř" "Ʒ" "Ƹ" "ƹ" "ƺ" "ƻ"
)
glitched+="${alt_chars[$((RANDOM % ${#alt_chars[@]}))]}"
else
glitched+="${text:$j:1}"
fi
done
printf "\r%*s${BOLD}${color}%s${NC}" "$padding" "" "$glitched"
sleep 0.07
done
sleep 0.15
local typed=""
for ((i=0; i<${#text}; i++)); do
typed+="${text:$i:1}"
printf "\r%*s${BOLD}${final_color}%s${NC}" "$padding" "" "$typed"
sleep "$delay"
done
for i in {1..2}; do
if [[ $((i % 2)) -eq 0 ]]; then
printf "\r%*s${BOLD}${final_color}%s${NC}" "$padding" "" "$text"
else
printf "\r%*s${BOLD}${WHITE}%s${NC}" "$padding" "" "$text"
fi
sleep 0.08
done
printf "\r%*s${BOLD}${final_color}%s${NC}\n" "$padding" "" "$text"
sleep 0.1
}

scan_logo() {
local term_width=$(tput cols 2>/dev/null || echo 80)
local logo=(
"███╗   ███╗ █████╗ ██╗     ██╗ ██████╗██╗ ██████╗ ██╗   ██╗███████╗"
"████╗ ████║██╔══██╗██║     ██║██╔════╝██║██╔═══██╗██║   ██║██╔════╝"
"██╔████╔██║███████║██║     ██║██║     ██║██║   ██║██║   ██║███████╗"
"██║╚██╔╝██║██╔══██║██║     ██║██║     ██║██║   ██║██║   ██║╚════██║"
"██║ ╚═╝ ██║██║  ██║███████╗██║╚██████╗██║╚██████╔╝╚██████╔╝███████║"
"╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚═╝ ╚═════╝╚═╝ ╚═════╝  ╚═════╝ ╚══════╝"
)
local max_len=0
for line in "${logo[@]}"; do
if [[ ${#line} -gt $max_len ]]; then
max_len=${#line}
fi
done
local padding=$(( (term_width - max_len) / 2 ))
if [[ $padding -lt 0 ]]; then
padding=0
fi
printf "%*s${BOLD}\e[38;5;39m%s${NC}\n" "$padding" "" "${logo[0]}"
sleep 0.08
printf "%*s${BOLD}\e[38;5;39m%s${NC}\n" "$padding" "" "${logo[1]}"
sleep 0.08
printf "%*s${BOLD}\e[38;5;39m%s${NC}\n" "$padding" "" "${logo[2]}"
sleep 0.08
printf "%*s${BOLD}\e[38;5;39m%s${NC}\n" "$padding" "" "${logo[3]}"
sleep 0.08
printf "%*s${BOLD}\e[38;5;39m%s${NC}\n" "$padding" "" "${logo[4]}"
sleep 0.08
printf "%*s${BOLD}\e[38;5;39m%s${NC}\n" "$padding" "" "${logo[5]}"
sleep 0.08
}

show_header() {
clear
scan_logo
echo ""
sleep 0.2
glitch_text_center "Created by Malicious For :" "${NEON_RED}" "${NEON_BLUE}" 0.04
sleep 0.3
glitch_text_center "DARK JUSTICE TEAM" "${NEON_CYAN}" "${NEON_LIME}" 0.06
sleep 0.3
glitch_text_center "Telegram : @XCEE_H3R" "${NEON_MAGENTA}" "${NEON_GOLD}" 0.05
echo ""
}

detect_os() {
if [[ -f /etc/os-release ]]; then
. /etc/os-release
OS_VERSION="$VERSION_ID"
OS_CODENAME="$VERSION_CODENAME"
echo ""
center_text "✓ OS detected: ${PRETTY_NAME}" "${BOLD}${NEON_GREEN}"
center_text "▶ Checking dependencies..." "${BOLD}${NEON_AQUA}"
echo ""
elif [[ -f /etc/lsb-release ]]; then
. /etc/lsb-release
OS_VERSION="$DISTRIB_RELEASE"
OS_CODENAME="$DISTRIB_CODENAME"
echo ""
center_text "✓ OS detected: ${DISTRIB_DESCRIPTION}" "${BOLD}${NEON_GREEN}"
center_text "▶ Checking dependencies..." "${BOLD}${NEON_AQUA}"
echo ""
else
OS_VERSION="unknown"
OS_CODENAME="unknown"
center_text "⚠ Unknown OS, continuing..." "${BOLD}${NEON_YELLOW}"
fi
}

show_progress() {
local current=$1
local total=$2
local width=40
local percentage=$((current * 100 / total))
local filled=$((percentage * width / 100))
local empty=$((width - filled))
if [[ $percentage -lt 100 ]]; then
printf "\r${BOLD}${NEON_CYAN}▓${NC}"
for ((i=0; i<filled; i++)); do
printf "${BOLD}${NEON_GREEN}█${NC}"
done
for ((i=0; i<empty; i++)); do
printf "${BOLD}${NEON_LAVENDER}░${NC}"
done
printf "${BOLD}${NEON_CYAN}▓${NC} ${BOLD}${NEON_GREEN}%3d%%${NC}" "$percentage"
fi
}

show_complete_progress() {
printf "\n${BOLD}${NEON_GREEN}▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ 100%% ${NEON_GREEN}✓${NC}\n"
}

check_root() {
if [[ $EUID -ne 0 ]]; then
echo -e "${BOLD}${NEON_RED}✗ This script must be run as root!${NC}"
echo -e "${BOLD}${NEON_YELLOW}Please run with sudo: sudo ./bash.sh${NC}"
exit 1
fi
}

setup_initial_mirror() {
local codename=$(get_ubuntu_codename)
echo -e "${BOLD}${NEON_AQUA}▶ Setting up initial mirrors for dependency installation...${NC}"

> /etc/apt/sources.list

echo "deb https://ubuntu-main.devneeds.ir/ ${codename} main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb https://ubuntu-main.devneeds.ir/ ${codename}-updates main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb https://ubuntu-main.devneeds.ir/ ${codename}-backports main restricted universe multiverse" >> /etc/apt/sources.list

echo "deb https://ubuntu-security.devneeds.ir/ ${codename}-security main restricted universe multiverse" >> /etc/apt/sources.list

echo -e "${BOLD}${NEON_GREEN}✓ Initial mirrors configured:${NC}"
echo -e "  ${NEON_CYAN}Main: https://ubuntu-main.devneeds.ir/${NC}"
echo -e "  ${NEON_CYAN}Security: https://ubuntu-security.devneeds.ir/${NC}"

echo -e "${BOLD}${NEON_AQUA}▶ Updating package lists...${NC}"
if apt-get update -qq 2>/dev/null; then
echo -e "${BOLD}${NEON_GREEN}✓ Package lists updated successfully${NC}"
return 0
else
echo -e "${BOLD}${NEON_RED}✗ Failed to update package lists. Network might be down or mirrors unreachable.${NC}"
echo -e "${BOLD}${NEON_YELLOW}⚠ Cannot proceed with dependency installation. Continuing with available tools...${NC}"
return 1
fi
}

check_dependencies() {
local missing=()
local has_curl=false
local has_wget=false
local has_ping=false
local has_dig=false
local has_nslookup=false
local has_awk=false
local has_sed=false
local has_grep=false
local has_bc=false
command -v curl &> /dev/null && has_curl=true || missing+=("curl")
command -v wget &> /dev/null && has_wget=true || missing+=("wget")
command -v ping &> /dev/null && has_ping=true || missing+=("iputils-ping")
command -v dig &> /dev/null && has_dig=true
command -v nslookup &> /dev/null && has_nslookup=true
if [[ "$has_dig" == false ]] && [[ "$has_nslookup" == false ]]; then
missing+=("dnsutils")
fi
command -v awk &> /dev/null || missing+=("awk")
command -v sed &> /dev/null || missing+=("sed")
command -v grep &> /dev/null || missing+=("grep")
command -v bc &> /dev/null || missing+=("bc")
if [[ ${#missing[@]} -eq 0 ]]; then
return 0
fi
echo -e "${BOLD}${NEON_YELLOW}⚠ Missing dependencies: ${missing[*]}${NC}"
echo -e "${BOLD}${NEON_AQUA}▶ Attempting to install...${NC}"
local pkg_manager=""
local install_cmd=""
if command -v apt-get &> /dev/null; then
pkg_manager="apt-get"
install_cmd="apt-get install -y -qq"
elif command -v yum &> /dev/null; then
pkg_manager="yum"
install_cmd="yum install -y"
elif command -v dnf &> /dev/null; then
pkg_manager="dnf"
install_cmd="dnf install -y"
else
echo -e "${BOLD}${NEON_YELLOW}⚠ No package manager found. Using built-in fallbacks...${NC}"
return 1
fi

local install_failed=0
for pkg in "${missing[@]}"; do
if [[ "$pkg" == "iputils-ping" ]] && [[ "$has_ping" == true ]]; then
continue
fi
if [[ "$pkg" == "dnsutils" ]] && { [[ "$has_dig" == true ]] || [[ "$has_nslookup" == true ]]; }; then
continue
fi
echo -e "${BOLD}${NEON_AQUA}▶ Installing ${pkg}...${NC}"
if ! eval "$install_cmd $pkg" 2>/dev/null; then
echo -e "${BOLD}${NEON_RED}✗ Failed to install ${pkg}${NC}"
install_failed=1
else
echo -e "${BOLD}${NEON_GREEN}✓ ${pkg} installed successfully${NC}"
fi
done

if [[ $install_failed -eq 1 ]]; then
echo -e "${BOLD}${NEON_YELLOW}⚠ Some packages failed to install. Continuing with available tools...${NC}"
return 1
else
echo -e "${BOLD}${NEON_GREEN}✓ All dependencies installed successfully${NC}"
return 0
fi
}

get_ubuntu_codename() {
if [[ -n "$OS_CODENAME" && "$OS_CODENAME" != "unknown" ]]; then
echo "$OS_CODENAME"
elif [[ -f /etc/lsb-release ]]; then
grep DISTRIB_CODENAME /etc/lsb-release | cut -d= -f2
else
case "$OS_VERSION" in
26.04) echo "plucky" ;;
26.10) echo "plucky" ;;
25.04) echo "plucky" ;;
25.10) echo "plucky" ;;
24.04|24.10) echo "noble" ;;
22.04|22.10) echo "jammy" ;;
20.04|20.10) echo "focal" ;;
18.04|18.10) echo "bionic" ;;
16.04|16.10) echo "xenial" ;;
*) echo "noble" ;;
esac
fi
}

validate_mirror() {
local base_url="$1"
local codename=$(get_ubuntu_codename)
local test_url="${base_url}dists/${codename}/Release"

if command -v curl &> /dev/null; then
local http_code
http_code=$(curl -L \
    --connect-timeout 5 \
    --max-time 10 \
    -o /dev/null \
    -s \
    -w "%{http_code}" \
    "$test_url" 2>/dev/null)
    
    if [[ "$http_code" == "200" ]]; then
        return 0
    fi
fi

return 1
}

test_mirror_speed() {
local base_url="$1"
local codename=$(get_ubuntu_codename)
local test_files=(
    "dists/${codename}/InRelease"
    "dists/${codename}/Release"
    "dists/${codename}/Contents-amd64.gz"
)
local temp_file="/tmp/mirror_test_$$"
local total_time=""
local file_size=0

trap 'rm -f "$temp_file" 2>/dev/null' RETURN

for test_file in "${test_files[@]}"; do
    local full_url="${base_url}${test_file}"
    
    if command -v curl &> /dev/null; then
        local response=$(curl -L \
            --connect-timeout 5 \
            --max-time 15 \
            -o "$temp_file" \
            -s \
            -w "%{http_code}:%{time_total}" \
            "$full_url" 2>/dev/null)
        
        local http_code=$(echo "$response" | cut -d: -f1)
        total_time=$(echo "$response" | cut -d: -f2)
        
        if [[ "$http_code" == "200" ]]; then
            file_size=$(stat -c%s "$temp_file" 2>/dev/null || stat -f%z "$temp_file" 2>/dev/null)
            
            if [[ -n "$total_time" && "$total_time" != "0" && "$total_time" != "0.000" && 
                  -n "$file_size" && "$file_size" -gt 0 ]]; then
                local speed=$(echo "scale=2; ($file_size / $total_time) / 1024" | bc -l 2>/dev/null)
                local score=$(echo "scale=2; $total_time * 1000" | bc -l 2>/dev/null)
                
                if [[ -n "$score" && "$score" != "0" ]]; then
                    if [[ -n "$speed" && "$speed" != "0" ]]; then
                        local adjusted_score=$(echo "scale=2; $score / ($speed / 10)" | bc -l 2>/dev/null)
                        if [[ -n "$adjusted_score" && "$adjusted_score" != "0" ]]; then
                            rm -f "$temp_file" 2>/dev/null
                            echo "$adjusted_score"
                            return 0
                        fi
                    fi
                    rm -f "$temp_file" 2>/dev/null
                    echo "$score"
                    return 0
                fi
            fi
        fi
    fi
    
    rm -f "$temp_file" 2>/dev/null
done

return 1
}

find_best_mirror() {
echo -e "${BOLD}${NEON_AQUA}▶ Testing and evaluating mirrors...${NC}"

if [[ ! -f "$MIRROR_FILE" ]]; then
echo -e "${BOLD}${NEON_RED}✗ mirror.txt not found!${NC}"
return 1
fi

local mirrors=()
while IFS= read -r line || [[ -n "$line" ]]; do
[[ -z "$line" || "$line" =~ ^# ]] && continue
line=$(echo "$line" | xargs)
if [[ -n "$line" && "$line" =~ ^https?:// ]]; then
if [[ ! "$line" =~ /ubuntu/$ ]] && [[ ! "$line" =~ /ubuntu$ ]]; then
line="${line%/}/"
fi
mirrors+=("$line")
fi
done < "$MIRROR_FILE"

if [[ ${#mirrors[@]} -eq 0 ]]; then
echo -e "${BOLD}${NEON_RED}✗ No valid mirrors found in mirror.txt!${NC}"
return 1
fi

local total=${#mirrors[@]}
local current=0
local best_score=999999
local best_mirror=""
local valid_mirrors=0

echo -e "${BOLD}${NEON_YELLOW}Found ${total} mirrors${NC}"
echo ""

for mirror in "${mirrors[@]}"; do
((current++))
show_progress $current $total

if ! validate_mirror "$mirror"; then
printf "\r%*s\r" "$(tput cols 2>/dev/null || echo 80)" ""
printf "${BOLD}${NEON_RED}✗ Invalid: ${mirror}${NC}                       \n"
continue
fi

local score=$(test_mirror_speed "$mirror")
if [[ -n "$score" && "$score" != "99999" && "$score" != "9999" && "$score" != "0" ]]; then
MIRROR_SPEEDS["$mirror"]="$score"
((valid_mirrors++))
if (( $(echo "$score < $best_score" | bc -l 2>/dev/null || echo "1") )); then
best_score="$score"
best_mirror="$mirror"
fi
printf "\r${BOLD}${NEON_GREEN}✓ ${mirror} - Score: ${score}ms${NC}                       \n"
else
printf "\r%*s\r" "$(tput cols 2>/dev/null || echo 80)" ""
printf "${BOLD}${NEON_RED}✗ Test failed: ${mirror}${NC}                       \n"
fi
done

show_complete_progress
echo ""

if [[ -n "$best_mirror" && $valid_mirrors -gt 0 ]]; then
BEST_MIRROR="$best_mirror"
echo -e "${BOLD}${NEON_GREEN}✓ Best mirror selected: ${BEST_MIRROR}${NC}"
echo -e "${BOLD}${NEON_GREEN}✓ Score: ${best_score}ms${NC}"
echo -e "${BOLD}${NEON_GREEN}✓ Valid mirrors: ${valid_mirrors}${NC}"
return 0
else
echo -e "${BOLD}${NEON_RED}✗ No valid mirrors found!${NC}"
return 1
fi
}

apply_mirror() {
if [[ -z "$BEST_MIRROR" ]]; then
echo -e "${BOLD}${NEON_RED}✗ No mirror to apply${NC}"
return 1
fi

if [[ -f "/etc/apt/sources.list" ]]; then
cp "/etc/apt/sources.list" "$BACKUP_MIRROR"
echo -e "${BOLD}${NEON_GREEN}✓ Sources.list backed up: ${BACKUP_MIRROR}${NC}"
fi

local codename=$(get_ubuntu_codename)
cat > "/etc/apt/sources.list" << EOF
deb ${BEST_MIRROR} ${codename} main restricted universe multiverse
deb ${BEST_MIRROR} ${codename}-updates main restricted universe multiverse
deb ${BEST_MIRROR} ${codename}-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ ${codename}-security main restricted universe multiverse
EOF

echo -e "${BOLD}${NEON_GREEN}✓ Mirror applied to sources.list${NC}"
}

test_dns() {
local dns_server="$1"
local test_domain="google.com"

if command -v ping &> /dev/null; then
local ping_output=$(ping -c 2 -W 2 "$dns_server" 2>/dev/null)
local ping_time=$(echo "$ping_output" | grep "time=" | head -1 | sed 's/.*time=\([0-9.]*\) ms.*/\1/' | cut -d. -f1)
if [[ -n "$ping_time" && "$ping_time" =~ ^[0-9]+$ ]] && [[ "$ping_time" -gt 0 ]]; then
echo "$ping_time"
return 0
fi
fi

if command -v dig &> /dev/null; then
local query_time=$(timeout 3 dig @"$dns_server" "$test_domain" +timeout=2 +tries=1 2>/dev/null | grep "Query time" | awk '{print $4}')
if [[ -n "$query_time" && "$query_time" =~ ^[0-9]+$ ]] && [[ "$query_time" -gt 0 ]]; then
echo "$query_time"
return 0
fi
fi

if command -v nslookup &> /dev/null; then
local start_time=$(date +%s%3N 2>/dev/null || echo "$(date +%s)000")
local result=$(timeout 3 nslookup "$test_domain" "$dns_server" 2>/dev/null)
local end_time=$(date +%s%3N 2>/dev/null || echo "$(date +%s)000")
if echo "$result" | grep -q "Address:"; then
local elapsed=$((end_time - start_time))
if [[ $elapsed -gt 0 && $elapsed -lt 10000 ]]; then
echo "$elapsed"
return 0
else
echo "50"
return 0
fi
fi
fi

if command -v curl &> /dev/null; then
local start_time=$(date +%s%3N 2>/dev/null || echo "$(date +%s)000")
curl -s --connect-timeout 2 --max-time 3 -o /dev/null "http://$dns_server:53" 2>/dev/null
local end_time=$(date +%s%3N 2>/dev/null || echo "$(date +%s)000")
local elapsed=$((end_time - start_time))
if [[ $elapsed -gt 0 && $elapsed -lt 5000 ]]; then
echo "$elapsed"
return 0
fi
fi

if command -v wget &> /dev/null; then
local start_time=$(date +%s%3N 2>/dev/null || echo "$(date +%s)000")
wget -q -O /dev/null --timeout=2 --tries=1 "http://$dns_server:53" 2>/dev/null
local end_time=$(date +%s%3N 2>/dev/null || echo "$(date +%s)000")
local elapsed=$((end_time - start_time))
if [[ $elapsed -gt 0 && $elapsed -lt 5000 ]]; then
echo "$elapsed"
return 0
fi
fi

if command -v nc &> /dev/null; then
local start_time=$(date +%s%3N 2>/dev/null || echo "$(date +%s)000")
nc -zv -w 2 "$dns_server" 53 2>/dev/null
local end_time=$(date +%s%3N 2>/dev/null || echo "$(date +%s)000")
local elapsed=$((end_time - start_time))
if [[ $elapsed -gt 0 && $elapsed -lt 5000 ]]; then
echo "$elapsed"
return 0
fi
fi

return 1
}

find_best_dns() {
echo -e "${BOLD}${NEON_AQUA}▶ Testing and evaluating DNS servers...${NC}"

if [[ ! -f "$DNS_FILE" ]]; then
echo -e "${BOLD}${NEON_RED}✗ dns.txt not found!${NC}"
return 1
fi

local dns_servers=()
while IFS= read -r line || [[ -n "$line" ]]; do
[[ -z "$line" || "$line" =~ ^# ]] && continue
line=$(echo "$line" | xargs)
if [[ -n "$line" && "$line" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
dns_servers+=("$line")
fi
done < "$DNS_FILE"

if [[ ${#dns_servers[@]} -eq 0 ]]; then
echo -e "${BOLD}${NEON_RED}✗ No valid DNS servers found in dns.txt!${NC}"
return 1
fi

local total=${#dns_servers[@]}
local current=0
local best_time=999999
local best_dns=""
local valid_dns=0

echo -e "${BOLD}${NEON_YELLOW}Found ${total} DNS servers${NC}"
echo ""

for dns in "${dns_servers[@]}"; do
((current++))
show_progress $current $total

local time=$(test_dns "$dns")
if [[ -n "$time" && "$time" != "" && "$time" != "999999" ]]; then
DNS_LATENCIES["$dns"]="$time"
((valid_dns++))
if (( $(echo "$time < $best_time" | bc -l 2>/dev/null || echo "1") )); then
best_time="$time"
best_dns="$dns"
fi
printf "\r${BOLD}${NEON_GREEN}✓ ${dns} - Response: ${time}ms${NC}                       \n"
else
printf "\r%*s\r" "$(tput cols 2>/dev/null || echo 80)" ""
printf "${BOLD}${NEON_RED}✗ Test failed: ${dns}${NC}                       \n"
fi
done

show_complete_progress
echo ""

if [[ -n "$best_dns" && $valid_dns -gt 0 ]]; then
BEST_DNS="$best_dns"
echo -e "${BOLD}${NEON_GREEN}✓ Best DNS selected: ${BEST_DNS}${NC}"
echo -e "${BOLD}${NEON_GREEN}✓ Response time: ${best_time}ms${NC}"
echo -e "${BOLD}${NEON_GREEN}✓ Valid DNS servers: ${valid_dns}${NC}"
return 0
else
echo -e "${BOLD}${NEON_RED}✗ No valid DNS servers found!${NC}"
return 1
fi
}

apply_dns() {
if [[ -z "$BEST_DNS" ]]; then
echo -e "${BOLD}${NEON_RED}✗ No DNS to apply${NC}"
return 1
fi

if [[ -f "/etc/resolv.conf" ]]; then
cp "/etc/resolv.conf" "$BACKUP_DNS"
echo -e "${BOLD}${NEON_GREEN}✓ resolv.conf backed up: ${BACKUP_DNS}${NC}"
fi

local dns_set=0

if command -v resolvectl &> /dev/null; then
echo -e "${BOLD}${NEON_AQUA}▶ Setting DNS with resolvectl${NC}"
local main_iface=$(ip route | grep default | awk '{print $5}' | head -n1)
if [[ -n "$main_iface" ]]; then
resolvectl dns "$main_iface" "$BEST_DNS" 2>/dev/null
resolvectl domain "$main_iface" "~." 2>/dev/null
echo -e "${BOLD}${NEON_GREEN}✓ DNS set with resolvectl${NC}"
dns_set=1
fi
fi

if [[ $dns_set -eq 0 ]] && command -v systemd-resolve &> /dev/null; then
echo -e "${BOLD}${NEON_AQUA}▶ Setting DNS with systemd-resolve${NC}"
local main_iface=$(ip route | grep default | awk '{print $5}' | head -n1)
if [[ -n "$main_iface" ]]; then
systemd-resolve --set-dns="$BEST_DNS" --interface="$main_iface" 2>/dev/null
echo -e "${BOLD}${NEON_GREEN}✓ DNS set with systemd-resolve${NC}"
dns_set=1
fi
fi

if [[ $dns_set -eq 0 ]] && command -v nmcli &> /dev/null; then
echo -e "${BOLD}${NEON_AQUA}▶ Setting DNS with NetworkManager${NC}"
local connection=$(nmcli -t -f NAME con show --active 2>/dev/null | head -n1)
if [[ -n "$connection" ]]; then
nmcli con mod "$connection" ipv4.dns "$BEST_DNS" 2>/dev/null
nmcli con mod "$connection" ipv4.ignore-auto-dns yes 2>/dev/null
nmcli con down "$connection" 2>/dev/null && nmcli con up "$connection" 2>/dev/null
echo -e "${BOLD}${NEON_GREEN}✓ DNS set with NetworkManager${NC}"
dns_set=1
fi
fi

if [[ $dns_set -eq 0 ]] && command -v resolvconf &> /dev/null; then
echo -e "${BOLD}${NEON_AQUA}▶ Setting DNS with resolvconf${NC}"
echo "nameserver $BEST_DNS" | resolvconf -a eth0 2>/dev/null
echo -e "${BOLD}${NEON_GREEN}✓ DNS set with resolvconf${NC}"
dns_set=1
fi

if [[ $dns_set -eq 0 ]] || [[ -f "/etc/resolv.conf" ]]; then
echo -e "${BOLD}${NEON_AQUA}▶ Setting resolv.conf directly${NC}"
if [[ -L "/etc/resolv.conf" ]]; then
rm -f "/etc/resolv.conf" 2>/dev/null
fi
cat > "/etc/resolv.conf" << EOF
nameserver ${BEST_DNS}
options edns0 trust-ad
search .
EOF

if [[ -f "/etc/systemd/resolved.conf" ]]; then
if ! grep -q "DNS=${BEST_DNS}" /etc/systemd/resolved.conf 2>/dev/null; then
sed -i.bak "s/^#DNS=/DNS=${BEST_DNS}/" /etc/systemd/resolved.conf 2>/dev/null
sed -i.bak "s/^DNS=/DNS=${BEST_DNS}/" /etc/systemd/resolved.conf 2>/dev/null
sed -i.bak "s/^#FallbackDNS=/FallbackDNS=/" /etc/systemd/resolved.conf 2>/dev/null
sed -i.bak "s/^#DNSSEC=/DNSSEC=no/" /etc/systemd/resolved.conf 2>/dev/null
systemctl restart systemd-resolved 2>/dev/null
echo -e "${BOLD}${NEON_GREEN}✓ systemd-resolved configured${NC}"
fi
fi
echo -e "${BOLD}${NEON_GREEN}✓ resolv.conf set${NC}"
fi

echo -e "${BOLD}${NEON_AQUA}▶ Testing DNS resolution...${NC}"
if command -v nslookup &> /dev/null; then
if nslookup google.com "$BEST_DNS" 2>/dev/null | grep -q "Address:"; then
echo -e "${BOLD}${NEON_GREEN}✓ DNS resolution working${NC}"
else
echo -e "${BOLD}${NEON_RED}✗ DNS resolution failed${NC}"
fi
elif command -v dig &> /dev/null; then
if dig @"$BEST_DNS" google.com +timeout=2 2>/dev/null | grep -q "ANSWER SECTION"; then
echo -e "${BOLD}${NEON_GREEN}✓ DNS resolution working${NC}"
else
echo -e "${BOLD}${NEON_RED}✗ DNS resolution failed${NC}"
fi
else
echo -e "${BOLD}${NEON_YELLOW}⚠ Cannot test DNS resolution (nslookup/dig not found)${NC}"
fi
}

show_results() {
echo ""
echo -e "${BOLD}${NEON_CYAN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${NEON_GREEN}Optimization Results${NC}"
echo -e "${BOLD}${NEON_CYAN}════════════════════════════════════════════════════════════════${NC}"
if [[ -n "$BEST_MIRROR" ]]; then
echo -e "${BOLD}${NEON_PINK}Best Mirror:${NC}  ${BOLD}${NEON_GREEN}${BEST_MIRROR}${NC}"
echo -e "${BOLD}${NEON_PINK}Score:${NC}        ${BOLD}${NEON_GREEN}${MIRROR_SPEEDS[$BEST_MIRROR]}ms${NC}"
fi
if [[ -n "$BEST_DNS" ]]; then
echo -e "${BOLD}${NEON_PINK}Best DNS:${NC}    ${BOLD}${NEON_GREEN}${BEST_DNS}${NC}"
echo -e "${BOLD}${NEON_PINK}Response:${NC}    ${BOLD}${NEON_GREEN}${DNS_LATENCIES[$BEST_DNS]}ms${NC}"
fi
echo -e "${BOLD}${NEON_CYAN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${NEON_GREEN}✓ Optimization completed successfully!${NC}"
echo -e "${BOLD}${NEON_YELLOW} Full log: ${LOG_FILE}${NC}"
}

main() {
check_root
show_header
detect_os

setup_initial_mirror

check_dependencies
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] ===== Starting optimization on ${OS_VERSION} (${OS_CODENAME}) =====" >> "$LOG_FILE"

echo -e "${BOLD}${NEON_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${NEON_YELLOW}Step 1: Mirror Optimization${NC}"
echo -e "${BOLD}${NEON_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if find_best_mirror; then
apply_mirror
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] Best mirror selected: ${BEST_MIRROR}" >> "$LOG_FILE"
else
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] Error selecting mirror" >> "$LOG_FILE"
echo -e "${BOLD}${NEON_RED}✗ Mirror step failed${NC}"
fi

echo ""
echo -e "${BOLD}${NEON_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${NEON_YELLOW}Step 2: DNS Optimization${NC}"
echo -e "${BOLD}${NEON_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if find_best_dns; then
apply_dns
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] Best DNS selected: ${BEST_DNS}" >> "$LOG_FILE"
else
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] Error selecting DNS" >> "$LOG_FILE"
echo -e "${BOLD}${NEON_RED}✗ DNS step failed${NC}"
fi

show_results
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] ===== Optimization completed =====" >> "$LOG_FILE"

echo -e "${BOLD}${NEON_GREEN} Script executed successfully!${NC}"
echo -e "${BOLD}${NEON_YELLOW} View log: cat ${LOG_FILE}${NC}"
echo -e "${BOLD}${NEON_YELLOW} Restore previous settings:${NC}"
echo -e "   ${BOLD}${NEON_CYAN}cp ${BACKUP_MIRROR} /etc/apt/sources.list${NC}"
echo -e "   ${BOLD}${NEON_CYAN}cp ${BACKUP_DNS} /etc/resolv.conf${NC}"
}

main "$@"
