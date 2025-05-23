#!/bin/bash

# Colors
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
CYAN='\e[36m'
BOLD='\e[1m'
NC='\e[0m'

print_title() {
  echo -e "\n${BOLD}${CYAN}===== $1 =====${NC}"
}

print_header() {
  clear
  echo -e "${BOLD}${CYAN}"
  echo -e "╔════════════════════════════════════════════╗"
  echo -e "║          🚀 DNS Changer by acor1          ║"
  echo -e "╚════════════════════════════════════════════╝"
  echo -e "${NC}\n"
}

install_dependencies() {
  print_title "🔍 Installing Dependencies"
  for pkg in curl jq bc iputils-ping; do
    if ! dpkg -s "$pkg" &>/dev/null; then
      echo -e "Installing $pkg..."
      apt-get install -y "$pkg" &>/dev/null && echo -e "$pkg installed successfully" || echo -e "${RED}Failed to install $pkg${NC}"
    else
      echo -e "$pkg is already installed"
    fi
  done
}

show_current_dns() {
  print_title "🔎 Current DNS Settings"
  if command -v resolvectl >/dev/null 2>&1; then
    resolvectl status
  else
    cat /etc/resolv.conf | grep nameserver
  fi
}

validate_ip() {
  local ip=$1
  local valid=$(echo "$ip" | grep -Eo '^([0-9]{1,3}\.){3}[0-9]{1,3}$')
  if [[ -z "$valid" ]]; then
    return 1
  else
    return 0
  fi
}

detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
  else
    OS=$(uname -s)
  fi
}

make_dns_persistent() {
  print_title "💾 Making DNS Persistent"
  detect_os

  case "$OS" in
    ubuntu|debian)
      if systemctl is-active --quiet systemd-resolved; then
        resolv_conf_file="/etc/systemd/resolved.conf"
        sed -i '/^#DNS=/d' $resolv_conf_file
        sed -i '/^DNS=/d' $resolv_conf_file
        echo "DNS=$dns1 $dns2" >> $resolv_conf_file
        systemctl restart systemd-resolved
        echo -e "${GREEN}DNS set in systemd-resolved.${NC}"
      else
        echo -e "nameserver $dns1\nnameserver $dns2" > /etc/resolv.conf
        echo -e "${YELLOW}systemd-resolved is not active. DNS set via /etc/resolv.conf.${NC}"
      fi
      ;;

    centos|fedora|rhel)
      nmcli con mod "$(nmcli -t -f NAME c show --active)" ipv4.dns "$dns1 $dns2"
      nmcli con mod "$(nmcli -t -f NAME c show --active)" ipv4.ignore-auto-dns yes
      nmcli con up "$(nmcli -t -f NAME c show --active)"
      echo -e "${GREEN}DNS set using NetworkManager (nmcli).${NC}"
      ;;

    arch)
      echo -e "[Resolve]\nDNS=$dns1 $dns2\nFallbackDNS=8.8.8.8" > /etc/systemd/resolved.conf
      systemctl restart systemd-resolved
      echo -e "${GREEN}DNS set for Arch-based system.${NC}"
      ;;

    *)
      echo -e "nameserver $dns1\nnameserver $dns2" > /etc/resolv.conf
      echo -e "${YELLOW}Unknown OS. DNS set via /etc/resolv.conf${NC}"
      ;;
  esac
}

speed_test_dns() {
  declare -A dns_list=(
    ["Google DNS"]="8.8.8.8"
    ["Cloudflare DNS"]="1.1.1.1"
    ["Quad9 DNS"]="9.9.9.9"
    ["OpenDNS"]="208.67.222.222"
    ["Yandex DNS"]="77.88.8.8"
  )

  print_title "🚀 Testing DNS Speed"
  fastest_dns=""
  fastest_time=99999

  for name in "${!dns_list[@]}"; do
    ip="${dns_list[$name]}"
    result=$(ping -c 1 -W 1 $ip 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | cut -d' ' -f1)
    if [[ -n "$result" ]]; then
      time_ms=$(echo $result | cut -d'.' -f1)
      echo -e "$name ($ip) -> ${time_ms}ms"
      if (( time_ms < fastest_time )); then
        fastest_time=$time_ms
        fastest_dns=$name
        fastest_ip=$ip
      fi
    else
      echo -e "$name ($ip) -> ${RED}No response${NC}"
    fi
  done

  echo -e "\n${GREEN}Fastest DNS is: $fastest_dns ($fastest_ip)${NC}"

  case $fastest_dns in
    "Google DNS") dns1=8.8.8.8; dns2=8.8.4.4;;
    "Cloudflare DNS") dns1=1.1.1.1; dns2=1.0.0.1;;
    "Quad9 DNS") dns1=9.9.9.9; dns2=149.112.112.112;;
    "OpenDNS") dns1=208.67.222.222; dns2=208.67.220.220;;
    "Yandex DNS") dns1=77.88.8.8; dns2=77.88.8.1;;
  esac

  apply_selected_dns
}

apply_selected_dns() {
  if command -v resolvectl >/dev/null 2>&1; then
    echo -e "DNS updated via systemd-resolved"
    ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
    iface=$(ip -o link show | awk -F': ' '{print $2}' | grep -v "lo" | head -n1)
    resolvectl revert "$iface"
    resolvectl dns "$iface" $dns1 $dns2
    resolvectl domain "$iface" "~."
    resolvectl default-route "$iface" yes
    resolvectl flush-caches
  else
    echo -e "DNS updated via /etc/resolv.conf"
    echo -e "nameserver $dns1\nnameserver $dns2" > /etc/resolv.conf
  fi

  make_dns_persistent

  print_title "✅ New DNS Configuration"
  cat /etc/resolv.conf

  print_title "📶 DNS Ping Results"
  for ip in $dns1 $dns2; do
    ping -c 2 $ip
    echo
  done

  print_title "🎉 Done"
  echo -e "${GREEN}DNS settings successfully updated.${NC}"
}

# (Rest of the script remains unchanged...)
