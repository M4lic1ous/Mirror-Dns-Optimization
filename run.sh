#!/bin/bash

NC='\033[0m'
BOLD='\033[1m'
BLINK='\033[5m'

NEON_CYAN='\033[38;2;0;255;255m'
NEON_BLUE='\033[38;2;0;150;255m'
NEON_GREEN='\033[38;2;0;255;100m'
NEON_MAGENTA='\033[38;2;255;0;255m'
NEON_YELLOW='\033[38;2;255;255;0m'
NEON_RED='\033[38;2;255;0;50m'
NEON_ORANGE='\033[38;2;255;100;0m'
NEON_PURPLE='\033[38;2;150;0;255m'

get_term_width() {
    local width
    if command -v tput &>/dev/null; then
        width=$(tput cols 2>/dev/null)
    fi
    if [[ -z "$width" || "$width" -lt 20 ]]; then
        width=80
    fi
    echo "$width"
}

strip_ansi() {
    echo -e "$1" | sed -E 's/\x1b\[[0-9;]*[a-zA-Z]//g'
}

visible_length() {
    local stripped
    stripped=$(strip_ansi "$1")
    echo "${#stripped}"
}

center_text() {
    local text="$1"
    local color="$2"
    local cols
    cols=$(get_term_width)

    if [[ -n "$color" ]]; then
        text="${color}${BOLD}${text}${NC}"
    fi

    local text_len
    text_len=$(visible_length "$text")

    local padding=$(( (cols - text_len) / 2 ))
    if [[ $padding -lt 0 ]]; then
        padding=0
    fi

    printf "%${padding}s" ""
    echo -e "${text}"
}

print_border() {
    local cols
    cols=$(get_term_width)

    local char="${1:-═}"
    local color="${2:-$NEON_BLUE}"

    local line=""
    for ((i=0; i<cols; i++)); do
        line+="$char"
    done

    echo -e "${color}${BOLD}${line}${NC}"
}

print_header() {
    clear
    print_border "═" "$NEON_BLUE"
    echo ""
    center_text "███╗   ███╗ █████╗ ██╗     ██╗ ██████╗██╗ ██████╗ ██╗   ██╗███████╗" "$NEON_CYAN"
    center_text "████╗ ████║██╔══██╗██║     ██║██╔════╝██║██╔═══██╗██║   ██║██╔════╝" "$NEON_CYAN"
    center_text "██╔████╔██║███████║██║     ██║██║     ██║██║   ██║██║   ██║███████╗" "$NEON_CYAN"
    center_text "██║╚██╔╝██║██╔══██║██║     ██║██║     ██║██║   ██║██║   ██║╚════██║" "$NEON_CYAN"
    center_text "██║ ╚═╝ ██║██║  ██║███████╗██║╚██████╗██║╚██████╔╝╚██████╔╝███████╗" "$NEON_CYAN"
    center_text "╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚═╝ ╚═════╝╚═╝ ╚═════╝  ╚═════╝ ╚══════╝" "$NEON_CYAN"
    echo ""
    center_text "Created by Malicious For :" "$NEON_MAGENTA"
    center_text "DARK JUSTICE TEAM" "$NEON_RED"
    center_text "Telegram : @XCEE_H3R" "$NEON_YELLOW"
    echo ""
    print_border "═" "$NEON_BLUE"
    echo ""
}

show_menu() {
    local cols
    cols=$(get_term_width)

    local title="SELECT YOUR TARGET SYSTEM"
    local -a menu_numbers=("1" "2" "3" "4")
    local -a menu_texts=("Kali Linux" "Ubuntu" "Debian" "Exit")
    local -a menu_colors=("$NEON_BLUE" "$NEON_BLUE" "$NEON_BLUE" "$NEON_RED")

    local max_len=0
    local title_len=${#title}
    if [[ $title_len -gt $max_len ]]; then
        max_len=$title_len
    fi

    for text in "${menu_texts[@]}"; do
        local text_len=${#text}
        local total_len=$((text_len + 4))
        if [[ $total_len -gt $max_len ]]; then
            max_len=$total_len
        fi
    done

    local menu_width=$((max_len + 4))
    if [[ $menu_width -lt 30 ]]; then
        menu_width=30
    fi

    local padding=$(( (cols - menu_width - 2) / 2 ))
    if [[ $padding -lt 0 ]]; then
        padding=0
    fi

    local menu_output=""

    local horizontal=""
    for ((i=0; i<menu_width; i++)); do
        horizontal+="─"
    done

    menu_output+="$(printf "%${padding}s" "")"
    menu_output+="${NEON_GREEN}${BOLD}┌${horizontal}┐${NC}\n"

    menu_output+="$(printf "%${padding}s" "")"
    menu_output+="${NEON_GREEN}${BOLD}│${NC}"

    local title_padding=$(( (menu_width - title_len) / 2 ))
    menu_output+="$(printf "%${title_padding}s" "")"
    menu_output+="${NEON_YELLOW}${BOLD}${title}${NC}"
    local remaining=$((menu_width - title_len - title_padding))
    menu_output+="$(printf "%${remaining}s" "")"

    menu_output+="${NEON_GREEN}${BOLD}│${NC}\n"

    menu_output+="$(printf "%${padding}s" "")"
    menu_output+="${NEON_GREEN}${BOLD}├${horizontal}┤${NC}\n"

    for i in "${!menu_numbers[@]}"; do
        local num="${menu_numbers[$i]}"
        local text="${menu_texts[$i]}"
        local color="${menu_colors[$i]}"

        local content="[${num}] ${text}"
        local content_len=${#content}

        menu_output+="$(printf "%${padding}s" "")"
        menu_output+="${NEON_GREEN}${BOLD}│${NC}  "
        menu_output+="${NEON_CYAN}${BOLD}[${num}]${NC} "
        menu_output+="${color}${BOLD}${text}${NC}"

        local remaining_space=$((menu_width - content_len - 2))
        if [[ $remaining_space -lt 0 ]]; then
            remaining_space=0
        fi
        menu_output+="$(printf "%${remaining_space}s" "")"

        menu_output+="${NEON_GREEN}${BOLD}│${NC}\n"
    done

    menu_output+="$(printf "%${padding}s" "")"
    menu_output+="${NEON_GREEN}${BOLD}└${horizontal}┘${NC}\n"

    echo -e "$menu_output"

    echo ""
    echo -ne "${NEON_YELLOW}${BOLD}┌─[${NEON_CYAN}DARK-JUSTICE${NEON_YELLOW}]─[${NEON_GREEN}SELECT${NEON_YELLOW}]\n└──╼ ${NC}${BOLD}"
}

execute_script() {
    local dir="$1"
    local script="$2"
    local display_name="$3"

    echo ""
    echo -e "${NEON_YELLOW}${BOLD}► Initializing ${NEON_CYAN}${display_name}${NEON_YELLOW} optimization...${NC}"
    print_border "═" "$NEON_BLUE"
    sleep 1

    if [[ ! -d "$dir" ]]; then
        echo -e "${NEON_RED}${BOLD}✘ ERROR: Directory './${dir}' not found!${NC}"
        echo -e "${NEON_YELLOW}${BOLD}Press any key to return to menu...${NC}"
        read -n 1 -s
        return 1
    fi

    if [[ ! -f "$dir/$script" ]]; then
        echo -e "${NEON_RED}${BOLD}✘ ERROR: Script './${dir}/${script}' not found!${NC}"
        echo -e "${NEON_YELLOW}${BOLD}Press any key to return to menu...${NC}"
        read -n 1 -s
        return 1
    fi

    echo -e "${NEON_GREEN}${BOLD}✔ Found ${display_name} script. Executing...${NC}"
    sleep 1

    cd "$dir" || {
        echo -e "${NEON_RED}${BOLD}✘ ERROR: Cannot change to directory './${dir}'${NC}"
        echo -e "${NEON_YELLOW}${BOLD}Press any key to return to menu...${NC}"
        read -n 1 -s
        return 1
    }

    chmod +x "$script" 2>/dev/null || {
        echo -e "${NEON_YELLOW}${BOLD}⚠ Warning: Could not set execute permission.${NC}"
    }

    print_border "═" "$NEON_MAGENTA"
    echo -e "${NEON_CYAN}${BOLD}▶ Running ${display_name} script ...${NC}"
    print_border "═" "$NEON_MAGENTA"
    sleep 1

    sudo bash "$script"

    local exit_code=$?

    cd - >/dev/null 2>&1

    echo ""
    print_border "═" "$NEON_MAGENTA"
    if [[ $exit_code -eq 0 ]]; then
        echo -e "${NEON_GREEN}${BOLD}✔ ${display_name} optimization completed successfully!${NC}"
    else
        echo -e "${NEON_RED}${BOLD}✘ ${display_name} optimization finished with exit code: ${exit_code}${NC}"
    fi
    print_border "═" "$NEON_MAGENTA"
    echo ""
    echo -e "${NEON_YELLOW}${BOLD}Press any key to return to menu...${NC}"
    read -n 1 -s

    return $exit_code
}

goodbye() {
    clear
    print_border "═" "$NEON_BLUE"
    echo ""
    center_text "███╗   ███╗ █████╗ ██╗     ██╗ ██████╗██╗ ██████╗ ██╗   ██╗███████╗" "$NEON_CYAN"
    center_text "████╗ ████║██╔══██╗██║     ██║██╔════╝██║██╔═══██╗██║   ██║██╔════╝" "$NEON_CYAN"
    center_text "██╔████╔██║███████║██║     ██║██║     ██║██║   ██║██║   ██║███████╗" "$NEON_CYAN"
    center_text "██║╚██╔╝██║██╔══██║██║     ██║██║     ██║██║   ██║██║   ██║╚════██║" "$NEON_CYAN"
    center_text "██║ ╚═╝ ██║██║  ██║███████╗██║╚██████╗██║╚██████╔╝╚██████╔╝███████╗" "$NEON_CYAN"
    center_text "╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚═╝ ╚═════╝╚═╝ ╚═════╝  ╚═════╝ ╚══════╝" "$NEON_CYAN"
    echo ""
    center_text "Created by Malicious For :" "$NEON_MAGENTA"
    center_text "DARK JUSTICE TEAM" "$NEON_RED"
    center_text "Telegram : @XCEE_H3R" "$NEON_YELLOW"
    echo ""
    print_border "═" "$NEON_BLUE"
    echo ""
    exit 0
}

trap '' INT

while true; do
    print_header
    show_menu

    read -r choice

    case "$choice" in
        1)
            execute_script "Kali" "kali.sh" "Kali Linux"
            ;;
        2)
            execute_script "Ubuntu" "Ubuntu.sh" "Ubuntu"
            ;;
        3)
            execute_script "Debian" "Debian.sh" "Debian"
            ;;
        4)
            goodbye
            ;;
        *)
            echo -e "\n${NEON_RED}${BOLD}✘ INVALID OPTION! Please choose 1-4.${NC}"
            sleep 1.5
            ;;
    esac
done

exit 0
