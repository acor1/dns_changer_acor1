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

  if grep -q "$dns1" /etc/resolv.conf && grep -q "$dns2" /etc/resolv.conf; then
    echo -e "${GREEN}DNS confirmed in /etc/resolv.conf${NC}"
  else
    echo -e "${RED}DNS not found in /etc/resolv.conf!${NC}"
  fi
}
