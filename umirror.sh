#!/bin/bash

clear

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m'

# List of mirrors
mirrors=(
    "https://ubuntu.pishgaman.net/ubuntu"
    "http://mirror.aminidc.com/ubuntu"
    "https://ubuntu.pars.host"
    "https://ir.ubuntu.sindad.cloud/ubuntu"
    "https://ubuntu.shatel.ir/ubuntu"
    "https://ubuntu.mobinhost.com/ubuntu"
    "https://mirror.iranserver.com/ubuntu"
    "https://mirror.arvancloud.ir/ubuntu"
    "http://ir.archive.ubuntu.com/ubuntu"
    "https://ubuntu.parsvds.com/ubuntu/"
)

declare -A mirror_speeds
available_mirrors=()

measure_speed() {
    local url=$1
    local output
    output=$(wget --timeout=5 --tries=1 -O /dev/null "$url" 2>&1 | grep -o '[0-9.]* [KM]B/s' | tail -1)

    if [[ -z $output ]]; then
        echo -1
    else
        if [[ $output == *K* ]]; then
            echo "${output/ KB\/s/}"
        else
            echo "$(echo "scale=2; ${output/ MB\/s/} * 1024" | bc)"
        fi
    fi
}

apply_mirror() {
    local mirror=$1
    local version
    version=$(lsb_release -sr | cut -d '.' -f 1)

    if [[ "$version" -ge 24 ]]; then
        sudo sed -i "s|https\?://[^ ]*|$mirror|g" /etc/apt/sources.list.d/ubuntu.sources
    else
        sudo sed -i "s|https\?://[^ ]*|$mirror|g" /etc/apt/sources.list
    fi

    sudo apt-get update
}

best_mirror=""
best_speed=0

echo -e "${BLUE}Mirror URL | Download Speed (KB/s)${NC}"
echo -e "----------------------------------"

for mirror in "${mirrors[@]}"; do
    speed=$(measure_speed "$mirror")

    if [[ $speed == -1 ]]; then
        echo -e "${CYAN}$mirror${WHITE} | ${RED}Failed${NC}"
        continue
    fi

    mirror_speeds["$mirror"]=$speed
    available_mirrors+=("$mirror")

    echo -e "${CYAN}$mirror${WHITE} | ${GREEN}${speed}${NC}"

    if (( $(echo "$speed > $best_speed" | bc -l) )); then
        best_speed=$speed
        best_mirror=$mirror
    fi
done

if [[ ${#available_mirrors[@]} -eq 0 ]]; then
    echo -e "${RED}No reachable mirrors found.${NC}"
    exit 1
fi

echo
echo -e "${BLUE}Select mirror mode:${NC}"
echo "1) Auto select (fastest)"
echo "2) Manual select (from list)"
echo "3) Manual input (custom URL)"
read -rp "Choice [1-3]: " choice

case "$choice" in
    1|"")
        selected_mirror="$best_mirror"
        echo -e "${GREEN}Auto-selected:${NC} $selected_mirror"
        ;;
    2)
        echo
        for i in "${!available_mirrors[@]}"; do
            m="${available_mirrors[$i]}"
            echo "$((i+1))) $m (${mirror_speeds[$m]} KB/s)"
        done
        read -rp "Select mirror number: " idx
        selected_mirror="${available_mirrors[$((idx-1))]}"
        ;;
    3)
        read -rp "Enter mirror URL: " selected_mirror
        ;;
    *)
        echo -e "${RED}Invalid choice.${NC}"
        exit 1
        ;;
esac

if [[ -z "$selected_mirror" ]]; then
    echo -e "${RED}No mirror selected.${NC}"
    exit 1
fi

echo -e "${BLUE}--------------------------------${NC}"
echo -e "${GREEN}Using mirror:${NC} ${CYAN}$selected_mirror${NC}"
echo -e "${BLUE}--------------------------------${NC}"

apply_mirror "$selected_mirror"
