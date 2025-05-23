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

make_dns_persistent() {
  print_title "💾 Making DNS Persistent"
  resolv_conf_file="/etc/systemd/resolved.conf"
  if [ -f "$resolv_conf_file" ]; then
    sed -i '/^#DNS=/d' $resolv_conf_file
    sed -i '/^DNS=/d' $resolv_conf_file
    echo -e "DNS=$dns1 $dns2" >> $resolv_conf_file
    systemctl restart systemd-resolved
    echo -e "${GREEN}DNS entries added to systemd resolved config.${NC}"
  else
    echo -e "${YELLOW}Warning: Could not find $resolv_conf_file. DNS may not persist after reboot.${NC}"
  fi
}

apply_dns() {
  method=$1
  case $method in
    1)
      print_title "⚙️ Applying Google DNS"
      dns1=8.8.8.8
      dns2=8.8.4.4
      ;;
    2)
      print_title "⚙️ Applying Cloudflare DNS"
      dns1=1.1.1.1
      dns2=1.0.0.1
      ;;
    3)
      print_title "⚙️ Applying Quad9 DNS"
      dns1=9.9.9.9
      dns2=149.112.112.112
      ;;
    4)
      print_title "⚙️ Applying OpenDNS"
      dns1=208.67.222.222
      dns2=208.67.220.220
      ;;
    5)
      print_title "⚙️ Applying Yandex DNS"
      dns1=77.88.8.8
      dns2=77.88.8.1
      ;;
    6)
      print_title "📝 Enter Custom DNS"
      echo -e "Please enter IP in correct format (e.g. 1.1.1.1)"
      read -p "Enter primary DNS: " dns1
      while ! validate_ip $dns1; do
        echo -e "${RED}Invalid format. Please try again.${NC}"
        read -p "Enter primary DNS: " dns1
      done
      read -p "Enter secondary DNS: " dns2
      while ! validate_ip $dns2; do
        echo -e "${RED}Invalid format. Please try again.${NC}"
        read -p "Enter secondary DNS: " dns2
      done
      ;;
    *)
      echo -e "${RED}Invalid option${NC}"
      exit 1
      ;;
  esac

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

main_menu() {
  print_header
  while true; do
    print_title "🧭 DNS Options"
    echo -e "1. Use Google DNS (8.8.8.8, 8.8.4.4)"
    echo -e "2. Use Cloudflare DNS (1.1.1.1, 1.0.0.1)"
    echo -e "3. Use Quad9 DNS (9.9.9.9, 149.112.112.112)"
    echo -e "4. Use OpenDNS (208.67.222.222, 208.67.220.220)"
    echo -e "5. Use Yandex DNS (77.88.8.8, 77.88.8.1)"
    echo -e "6. Use Custom DNS"
    echo -e "7. Show Current DNS"
    echo -e "8. Exit"

    read -p $'\nChoose an option [1-8]: ' choice
    case $choice in
      1|2|3|4|5|6)
        apply_dns $choice
        ;;
      7)
        show_current_dns
        ;;
      8)
        echo -e "${YELLOW}Exiting...${NC}"
        sleep 1
        clear
        break
        ;;
      *)
        echo -e "${RED}Invalid option. Try again.${NC}"
        ;;
    esac
  done
}

install_dependencies
main_menu
