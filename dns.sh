#!/bin/bash
set -uo pipefail

VERSION="3.5.0"
AUTHOR="acor1"

BOLD='\033[1m'
DIM='\033[2m'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
PURPLE='\033[1;35m'
WHITE='\033[1;37m'
NC='\033[0m'
CHECKMARK="✔"
CROSS="✗"

HISTORY_LOG="/var/log/acor1-dns.log"
LAST_DNS_FILE="/etc/acor1-dns.last"
BACKUP_FILE="/etc/resolv.conf.acor1.bak"
SPLIT_CONF_DIR="/etc/systemd/resolved.conf.d"

if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
  cat <<EOF
DNS Changer v${VERSION} by ${AUTHOR}
=========================================
Interactive, multi-distro DNS changer with encrypted DNS (DoT),
Split DNS, real resolve benchmarks, and DNS leak testing.

Usage:
  sudo $0              Launch interactive menu
  sudo $0 --help       Show this help
  sudo $0 --version    Show version
  sudo $0 --restore    Restore previous DNS from backup
  sudo $0 --no-deps    Skip dependency installation

Features:
  - Quick apply: Google, Cloudflare, Quad9, Shecan, 403
  - Custom DNS with validation
  - Smart Benchmark (real DNS resolve timing)
  - DNS-over-TLS (requires systemd-resolved 240+)
  - Split DNS (persistent, domain-specific)
  - DNS Leak Test
  - Cache Statistics
  - Change History log
  - Automatic backup & restore

Compatible with:
  Ubuntu 18.04+ / Debian 10+ / CentOS 7+ / Rocky 9 / Alpine / Arch

EOF
  exit 0
fi

if [[ "${1:-}" == "--version" ]] || [[ "${1:-}" == "-v" ]]; then
  echo "acor1-dns-changer ${VERSION}"
  exit 0
fi

if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}❌ This script must be run as root (use sudo).${NC}"
  exit 1
fi

HAS_SYSTEMD=0
HAS_RESOLVECTL=0
HAS_RESOLVED=0
SYSTEMD_VERSION=0
RESOLVED_VERSION=0

if command -v systemctl >/dev/null 2>&1 && [[ -d /run/systemd/system ]]; then
  HAS_SYSTEMD=1
fi

if command -v resolvectl >/dev/null 2>&1; then
  HAS_RESOLVECTL=1
fi

if [[ $HAS_SYSTEMD -eq 1 ]]; then
  if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
    HAS_RESOLVED=1
  elif systemctl is-enabled --quiet systemd-resolved 2>/dev/null; then
    HAS_RESOLVED=1
  elif [[ -f /run/systemd/resolve/resolv.conf ]] || [[ -f /run/systemd/resolve/stub-resolv.conf ]]; then
    HAS_RESOLVED=1
  elif [[ -L /etc/resolv.conf ]] && readlink -f /etc/resolv.conf 2>/dev/null | grep -q "systemd/resolve"; then
    HAS_RESOLVED=1
  fi
fi

if [[ $HAS_RESOLVED -eq 0 ]] && [[ $HAS_RESOLVECTL -eq 1 ]]; then
  HAS_RESOLVED=1
fi

if [[ $HAS_SYSTEMD -eq 1 ]]; then
  SYSTEMD_VERSION=$(systemctl --version 2>/dev/null | head -1 | awk '{print $2}')
  if ! [[ "$SYSTEMD_VERSION" =~ ^[0-9]+$ ]]; then
    SYSTEMD_VERSION=0
  fi
fi

if [[ $HAS_RESOLVED -eq 1 ]]; then
  if [[ $SYSTEMD_VERSION -gt 0 ]]; then
    RESOLVED_VERSION=$SYSTEMD_VERSION
  else
    RESOLVED_VERSION=$(resolvectl --version 2>/dev/null | head -1 | grep -oE '[0-9]+' | head -1)
    if ! [[ "$RESOLVED_VERSION" =~ ^[0-9]+$ ]]; then
      RESOLVED_VERSION=0
    fi
  fi
fi

supports_dot() {
  [[ $HAS_RESOLVECTL -eq 1 ]] && [[ $RESOLVED_VERSION -ge 240 ]]
}

print_header() {
  clear
  echo -e "${CYAN}${BOLD}"
  cat <<'EOF'
   ██████╗ ███╗   ██╗███████╗
   ██╔══██╗████╗  ██║██╔════╝
   ██║  ██║██╔██╗ ██║███████╗
   ██║  ██║██║╚██╗██║╚════██║
   ██████╔╝██║ ╚████║███████║
   ╚═════╝ ╚═╝  ╚═══╝╚══════╝
EOF
  echo -e "${PURPLE}      🚀  DNS Changer v${VERSION} by ${AUTHOR}  ☄️${NC}"
  echo -e "${DIM}      ────────────────────────────────────${NC}"
}

print_title() {
  echo -e "\n${BOLD}${CYAN}  ══════════════════════════════════════════${NC}"
  echo -e "${BOLD}${CYAN}     $1${NC}"
  echo -e "${BOLD}${CYAN}  ══════════════════════════════════════════${NC}"
}

detect_pkg_manager() {
  if command -v apt-get >/dev/null 2>&1; then echo "apt"; return; fi
  if command -v dnf >/dev/null 2>&1; then echo "dnf"; return; fi
  if command -v yum >/dev/null 2>&1; then echo "yum"; return; fi
  if command -v apk >/dev/null 2>&1; then echo "apk"; return; fi
  if command -v pacman >/dev/null 2>&1; then echo "pacman"; return; fi
  echo "unknown"
}

pkg_installed() {
  local pkg="$1"
  local mgr
  mgr=$(detect_pkg_manager)
  case "$mgr" in
    apt) dpkg -s "$pkg" &>/dev/null ;;
    dnf|yum) rpm -q "$pkg" &>/dev/null ;;
    apk) apk info -e "$pkg" &>/dev/null ;;
    pacman) pacman -Qi "$pkg" &>/dev/null ;;
    *) return 1 ;;
  esac
}

install_pkg_one() {
  local pkg="$1"
  local mgr
  mgr=$(detect_pkg_manager)
  case "$mgr" in
    apt) apt-get install -y "$pkg" >/dev/null 2>&1 ;;
    dnf) dnf install -y "$pkg" >/dev/null 2>&1 ;;
    yum) yum install -y "$pkg" >/dev/null 2>&1 ;;
    apk) apk add "$pkg" >/dev/null 2>&1 ;;
    pacman) pacman -S --noconfirm "$pkg" >/dev/null 2>&1 ;;
    *) return 1 ;;
  esac
}

install_dependencies() {
  print_title "🔍 Checking Dependencies"

  local mgr
  mgr=$(detect_pkg_manager)
  if [[ "$mgr" == "unknown" ]]; then
    echo -e "  ${RED}${CROSS} No supported package manager found.${NC}"
    return 0
  fi

  if [[ "$mgr" == "apt" ]]; then
    if ! timeout 45 apt-get update -qq >/dev/null 2>&1; then
      echo -e "  ${YELLOW}⚠${NC} apt-get update failed/timed out — continuing anyway"
    fi
  fi

  local pkgs=()
  case "$mgr" in
    apt) pkgs=(curl jq bc iputils-ping dnsutils) ;;
    dnf|yum) pkgs=(curl jq bc iputils bind-utils) ;;
    apk) pkgs=(curl jq bc iputils bind-tools) ;;
    pacman) pkgs=(curl jq bc iputils bind) ;;
  esac

  local failed=()
  for pkg in "${pkgs[@]}"; do
    if pkg_installed "$pkg"; then
      echo -e "  ${GREEN}${CHECKMARK}${NC} $pkg"
    else
      if timeout 90 bash -c "$(declare -f install_pkg_one); install_pkg_one '$pkg'" >/dev/null 2>&1; then
        echo -e "  ${GREEN}${CHECKMARK}${NC} $pkg ${DIM}(installed)${NC}"
      else
        echo -e "  ${YELLOW}⚠${NC} $pkg ${DIM}(skipped — install failed)${NC}"
        failed+=("$pkg")
      fi
    fi
  done

  if ! command -v dig >/dev/null 2>&1; then
    echo -e "  ${YELLOW}⚠${NC} dig not found — resolve tests will be limited"
  fi
  if ! command -v bc >/dev/null 2>&1; then
    echo -e "  ${YELLOW}⚠${NC} bc not found — some math may be limited"
  fi

  if (( ${#failed[@]} > 0 )); then
    echo -e "  ${YELLOW}ℹ${NC}  Failed to install: ${failed[*]}"
    echo -e "  ${DIM}     (Core functionality will still work)${NC}"
  fi
}

validate_ip() {
  local ip="$1"
  if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    local IFS='.'
    read -ra octets <<< "$ip"
    for oct in "${octets[@]}"; do
      (( oct < 0 || oct > 255 )) && return 1
    done
    return 0
  fi
  return 1
}

resolve_time() {
  local dns="$1"
  local domain="${2:-google.com}"
  if ! command -v dig >/dev/null 2>&1; then
    echo "9999"
    return
  fi
  local t
  t=$(timeout 5 dig +time=2 +tries=1 @"$dns" "$domain" +noall +stats 2>/dev/null \
      | grep -oE 'Query time: [0-9]+' | grep -oE '[0-9]+' || echo "")
  echo "${t:-9999}"
}

benchmark_dns() {
  local dns="$1"
  local domains=(google.com cloudflare.com github.com wikipedia.org microsoft.com)
  local total=0
  local count=0
  for d in "${domains[@]}"; do
    local t
    t=$(resolve_time "$dns" "$d")
    if (( t < 9999 )); then
      total=$((total + t))
      count=$((count + 1))
    fi
  done
  if (( count > 0 )); then
    echo $((total / count))
  else
    echo 9999
  fi
}

ping_time() {
  local ip="$1"
  local t
  t=$(timeout 4 ping -c 1 -W 2 "$ip" 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | cut -d' ' -f1 | cut -d'.' -f1 || true)
  echo "${t:-9999}"
}

backup_dns() {
  if [[ ! -f "$BACKUP_FILE" ]]; then
    cp /etc/resolv.conf "$BACKUP_FILE" 2>/dev/null || true
  fi
}

log_dns_change() {
  local name="$1"
  local dns1="$2"
  local dns2="$3"
  echo "$(date '+%Y-%m-%d %H:%M:%S') | $name | $dns1, $dns2" >> "$HISTORY_LOG" 2>/dev/null || true
  echo "$name|$dns1|$dns2" > "$LAST_DNS_FILE" 2>/dev/null || true
}

get_primary_iface() {
  local iface=""
  if command -v ip >/dev/null 2>&1; then
    iface=$(ip -o link show 2>/dev/null | awk -F': ' '{print $2}' | grep -v "lo" | head -n1 || true)
  fi
  if [[ -z "$iface" ]] && command -v ifconfig >/dev/null 2>&1; then
    iface=$(ifconfig -a 2>/dev/null | grep -E '^[a-z]' | awk '{print $1}' | grep -v "lo" | head -n1 || true)
  fi
  if [[ -z "$iface" ]]; then
    iface="eth0"
  fi
  echo "$iface"
}

write_resolv_conf() {
  local dns1="$1"
  local dns2="$2"

  if [[ -L /etc/resolv.conf ]]; then
    local target
    target=$(readlink -f /etc/resolv.conf 2>/dev/null || echo "")
    if [[ "$target" == *"systemd/resolve"* ]] && [[ $HAS_RESOLVED -eq 1 ]]; then
      echo -e "  ${YELLOW}⚠${NC} systemd-resolved manages /etc/resolv.conf — skipping file write."
      return 0
    fi
    rm -f /etc/resolv.conf 2>/dev/null || true
  fi

  {
    echo "# Managed by acor1 dns-changer"
    echo "nameserver $dns1"
    echo "nameserver $dns2"
  } > /etc/resolv.conf 2>/dev/null || {
    echo -e "  ${RED}${CROSS} Failed to write /etc/resolv.conf${NC}"
    return 1
  }
}

make_dns_persistent() {
  local dns1="$1"
  local dns2="$2"
  local dot_name="${3:-}"

  if [[ $HAS_RESOLVED -eq 1 ]]; then
    local resolved_conf="/etc/systemd/resolved.conf"
    if [[ -f "$resolved_conf" ]]; then
      cp "$resolved_conf" "${resolved_conf}.acor1.bak" 2>/dev/null || true
      sed -i '/^#\?DNS=/d' "$resolved_conf" 2>/dev/null || true
      sed -i '/^#\?FallbackDNS=/d' "$resolved_conf" 2>/dev/null || true
      sed -i '/^#\?DNSOverTLS=/d' "$resolved_conf" 2>/dev/null || true

      {
        if [[ -n "$dot_name" ]] && supports_dot; then
          echo "DNS=$dns1#$dot_name $dns2#$dot_name"
          echo "DNSOverTLS=yes"
        else
          echo "DNS=$dns1 $dns2"
          echo "DNSOverTLS=no"
        fi
        echo "FallbackDNS=1.1.1.1 8.8.8.8"
      } >> "$resolved_conf"

      systemctl restart systemd-resolved 2>/dev/null || true
      echo -e "  ${GREEN}${CHECKMARK}${NC} Persisted in systemd-resolved."
    fi
  fi

  if [[ -f /etc/network/interfaces ]]; then
    if ! grep -q "acor1-dns" /etc/network/interfaces 2>/dev/null; then
      {
        echo ""
        echo "# acor1-dns"
        echo "dns-nameservers $dns1 $dns2"
      } >> /etc/network/interfaces 2>/dev/null || true
    fi
  fi
}

apply_dns() {
  local dns1="$1"
  local dns2="$2"
  local name="${3:-Custom}"
  local dot_name="${4:-}"

  backup_dns
  print_title "⚙️  Applying $name"

  local applied_via="resolv.conf"

  if [[ $HAS_RESOLVECTL -eq 1 ]]; then
    local iface
    iface=$(get_primary_iface)

    if [[ -n "$iface" ]]; then
      resolvectl revert "$iface" 2>/dev/null || true

      if [[ -n "$dot_name" ]] && supports_dot; then
        if resolvectl dns "$iface" "${dns1}#${dot_name}" "${dns2}#${dot_name}" 2>/dev/null; then
          echo -e "  ${GREEN}${CHECKMARK}${NC} DNS-over-TLS enabled: $dns1 → $dot_name"
          applied_via="resolvectl+DoT"
        else
          resolvectl dns "$iface" "$dns1" "$dns2" 2>/dev/null || true
          applied_via="resolvectl"
        fi
      elif [[ -n "$dot_name" ]]; then
        echo -e "  ${YELLOW}⚠${NC} DoT not supported (systemd-resolved <240). Applying plain DNS."
        resolvectl dns "$iface" "$dns1" "$dns2" 2>/dev/null || true
        applied_via="resolvectl"
      else
        resolvectl dns "$iface" "$dns1" "$dns2" 2>/dev/null || true
        applied_via="resolvectl"
      fi

      resolvectl domain "$iface" "~." 2>/dev/null || true
      resolvectl default-route "$iface" yes 2>/dev/null || true
      resolvectl flush-caches 2>/dev/null || true

      if [[ -L /etc/resolv.conf ]] && [[ -e /run/systemd/resolve/resolv.conf ]]; then
        ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf 2>/dev/null || true
      fi

      echo -e "  ${GREEN}${CHECKMARK}${NC} DNS updated via systemd-resolved on $iface"
    fi
  fi

  if [[ "$applied_via" == "resolv.conf" ]]; then
    write_resolv_conf "$dns1" "$dns2" && \
      echo -e "  ${GREEN}${CHECKMARK}${NC} DNS updated via /etc/resolv.conf"
  fi

  make_dns_persistent "$dns1" "$dns2" "$dot_name"
  log_dns_change "$name" "$dns1" "$dns2"

  print_title "✅ New DNS Configuration"
  if [[ -f /etc/resolv.conf ]]; then
    grep -E '^nameserver' /etc/resolv.conf 2>/dev/null | sed 's/^/  /' || true
  fi
  if [[ -f /etc/systemd/resolved.conf ]] && [[ $HAS_RESOLVED -eq 1 ]]; then
    grep -E '^DNS=' /etc/systemd/resolved.conf 2>/dev/null | sed 's/^/  /' || true
  fi

  print_title "📶 Connection Test"
  for ip in "$dns1" "$dns2"; do
    local p t
    p=$(ping_time "$ip")
    t=$(resolve_time "$ip")
    if (( p < 9999 )); then
      echo -e "  ${GREEN}${CHECKMARK}${NC} $ip → ping: ${p}ms  |  resolve: ${t}ms"
    else
      echo -e "  ${RED}${CROSS}${NC} $ip → No response"
    fi
  done

  print_title "🎉 Done"
  echo -e "  ${GREEN}DNS successfully updated to $name.${NC}"
}

smart_benchmark() {
  declare -A dns_list=(
    ["Cloudflare"]="1.1.1.1"
    ["Google"]="8.8.8.8"
    ["Quad9"]="9.9.9.9"
    ["OpenDNS"]="208.67.222.222"
    ["Yandex"]="77.88.8.8"
    ["Shecan"]="178.22.122.100"
    ["403"]="10.202.10.202"
  )

  print_title "⚡ Smart Benchmark (real resolve test)"
  echo -e "  ${DIM}Testing 7 providers × 5 domains — may take up to 1 minute...${NC}\n"
  printf "  ${BOLD}%-15s %-18s %-10s %-10s${NC}\n" "Provider" "IP" "Ping" "Resolve"
  echo -e "  ${DIM}──────────────────────────────────────────────────${NC}"

  local fastest_name="" fastest_ip="" fastest_score=999999

  for name in "${!dns_list[@]}"; do
    local ip="${dns_list[$name]}"
    local p r
    p=$(ping_time "$ip")
    r=$(benchmark_dns "$ip")

    if (( r >= 9999 )); then
      printf "  %-15s %-18s ${RED}%-10s %-10s${NC}\n" "$name" "$ip" "timeout" "timeout"
      continue
    fi

    printf "  %-15s %-18s ${GREEN}%-8sms ${CYAN}%-8sms${NC}\n" "$name" "$ip" "$p" "$r"

    if (( r < fastest_score )); then
      fastest_score=$r
      fastest_name=$name
      fastest_ip=$ip
    fi
  done

  echo
  if [[ -z "$fastest_name" ]]; then
    echo -e "  ${RED}❌ No reachable DNS found.${NC}"
    return
  fi

  echo -e "  ${GREEN}${BOLD}🏆 Winner: $fastest_name ($fastest_ip) — avg resolve: ${fastest_score}ms${NC}"

  case "$fastest_name" in
    "Cloudflare") apply_dns 1.1.1.1 1.0.0.1 "Cloudflare DNS" ;;
    "Google")     apply_dns 8.8.8.8 8.8.4.4 "Google DNS" ;;
    "Quad9")      apply_dns 9.9.9.9 149.112.112.112 "Quad9 DNS" ;;
    "OpenDNS")    apply_dns 208.67.222.222 208.67.220.220 "OpenDNS" ;;
    "Yandex")     apply_dns 77.88.8.8 77.88.8.1 "Yandex DNS" ;;
    "Shecan")     apply_dns 178.22.122.100 185.51.200.2 "Shecan DNS" ;;
    "403")        apply_dns 10.202.10.202 10.202.10.102 "403 DNS" ;;
  esac
}

dot_menu() {
  print_title "🔒 Encrypted DNS (DoT)"

  if ! supports_dot; then
    echo -e "  ${YELLOW}⚠${NC} systemd-resolved ${RESOLVED_VERSION:-unknown} detected."
    echo -e "  ${DIM}DoT requires systemd-resolved 240+ (Ubuntu 20.04+).${NC}"
    echo -e "  ${DIM}Please upgrade your system to use encrypted DNS.${NC}"
    return
  fi

  echo -e "  ${DIM}Traffic is encrypted — ISP cannot see your DNS queries.${NC}\n"
  echo -e "    ${GREEN}[1]${NC}  Cloudflare DoT  ${DIM}(1.1.1.1#cloudflare-dns.com)${NC}"
  echo -e "    ${GREEN}[2]${NC}  Google DoT      ${DIM}(8.8.8.8#dns.google)${NC}"
  echo -e "    ${GREEN}[3]${NC}  Quad9 DoT       ${DIM}(9.9.9.9#dns.quad9.net)${NC}"
  echo -e "    ${GREEN}[4]${NC}  AdGuard DoT     ${DIM}(94.140.14.14#dns.adguard-dns.com)${NC}"
  echo -e "    ${RED}[0]${NC}  Back"
  echo
  printf "${PURPLE}${BOLD}  ➤ Select: ${NC}"
  read -r c

  case $c in
    1) apply_dns 1.1.1.1 1.0.0.1 "Cloudflare DoT" "cloudflare-dns.com" ;;
    2) apply_dns 8.8.8.8 8.8.4.4 "Google DoT" "dns.google" ;;
    3) apply_dns 9.9.9.9 149.112.112.112 "Quad9 DoT" "dns.quad9.net" ;;
    4) apply_dns 94.140.14.14 94.140.15.15 "AdGuard DoT" "dns.adguard-dns.com" ;;
    0) return ;;
    *) echo -e "${RED}  ❌ Invalid.${NC}" ;;
  esac
}

leak_test() {
  print_title "🔍 DNS Leak Test"

  if [[ $HAS_RESOLVECTL -eq 0 ]]; then
    echo -e "  ${YELLOW}⚠${NC} resolvectl not available. Showing /etc/resolv.conf:${NC}\n"
    cat /etc/resolv.conf 2>/dev/null | sed 's/^/  /' || true
    return
  fi

  local iface
  iface=$(get_primary_iface)
  echo -e "  ${DIM}Checking DNS on $iface...${NC}\n"
  resolvectl status "$iface" 2>/dev/null | head -25 | sed 's/^/  /' || true

  echo
  local dns_servers
  dns_servers=$(resolvectl dns "$iface" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -2 || true)

  if [[ -z "$dns_servers" ]]; then
    echo -e "  ${RED}${CROSS} No DNS configured on $iface — potential leak!${NC}"
  else
    echo -e "  ${GREEN}${CHECKMARK} DNS on $iface:${NC}"
    while IFS= read -r s; do
      [[ -z "$s" ]] && continue
      echo -e "     → $s"
    done <<< "$dns_servers"
  fi

  echo
  if command -v dig >/dev/null 2>&1; then
    local real_ip
    real_ip=$(timeout 5 dig +short +time=3 @resolver1.opendns.com myip.opendns.com 2>/dev/null | head -1 || true)
    if [[ -n "$real_ip" ]]; then
      echo -e "  ${CYAN}🌐 Your public IP: $real_ip${NC}"
    fi
  fi
}

cache_stats() {
  print_title "📊 DNS Cache Statistics"
  if [[ $HAS_RESOLVECTL -eq 1 ]]; then
    resolvectl statistics 2>/dev/null | sed 's/^/  /' || echo -e "  ${YELLOW}No stats available.${NC}"
  else
    echo -e "  ${YELLOW}systemd-resolved not available.${NC}"
  fi
}

show_history() {
  print_title "🕒 DNS Change History"
  if [[ -f "$HISTORY_LOG" ]]; then
    echo -e "  ${DIM}File: $HISTORY_LOG${NC}\n"
    nl -w4 -s'  ' "$HISTORY_LOG" 2>/dev/null | while IFS= read -r line; do
      echo -e "  ${GREEN}${line}${NC}"
    done
  else
    echo -e "  ${YELLOW}No history yet.${NC}"
  fi
}

split_dns() {
  print_title "🎯 Split DNS (Domain-specific)"

  if [[ $HAS_RESOLVECTL -eq 0 ]]; then
    echo -e "  ${YELLOW}⚠${NC} Split DNS requires systemd-resolved."
    return
  fi

  echo -e "  ${DIM}Use a special DNS only for a specific domain.${NC}"
  echo -e "  ${DIM}Config is persisted in ${SPLIT_CONF_DIR}/.${NC}\n"

  local domain dns
  read -rp "  Domain (e.g. example.com): " domain
  if [[ ! "$domain" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*\.[a-zA-Z]{2,}$ ]]; then
    echo -e "  ${RED}❌ Invalid domain.${NC}"
    return
  fi
  read -rp "  DNS for this domain: " dns
  if ! validate_ip "$dns"; then
    echo -e "  ${RED}❌ Invalid IP.${NC}"
    return
  fi

  local safe_domain
  safe_domain=$(echo "$domain" | tr '.' '_')
  local conf_file="${SPLIT_CONF_DIR}/acor1-split-${safe_domain}.conf"

  mkdir -p "$SPLIT_CONF_DIR"

  local iface
  iface=$(get_primary_iface)

  cat > "$conf_file" <<EOF
[Resolve]
DNS=$dns
Domains=~$domain
EOF

  resolvectl domain "$iface" "~$domain" 2>/dev/null || true
  resolvectl dns "$iface" "$dns" 2>/dev/null || true
  resolvectl flush-caches 2>/dev/null || true

  echo
  echo -e "  ${GREEN}${CHECKMARK}${NC} Domain ${WHITE}$domain${NC} → ${WHITE}$dns${NC}"
  echo -e "  ${GREEN}${CHECKMARK}${NC} Persisted in ${DIM}$conf_file${NC}"
  echo -e "  ${GREEN}${CHECKMARK}${NC} Applied to interface ${WHITE}$iface${NC}"
}

restore_dns() {
  print_title "♻️  Restoring Default DNS"

  local restored=0

  if [[ -f "$BACKUP_FILE" ]]; then
    cp "$BACKUP_FILE" /etc/resolv.conf
    restored=1
    echo -e "  ${GREEN}${CHECKMARK}${NC} /etc/resolv.conf restored."
  fi

  if [[ -f /etc/systemd/resolved.conf.acor1.bak ]] && [[ $HAS_RESOLVED -eq 1 ]]; then
    cp /etc/systemd/resolved.conf.acor1.bak /etc/systemd/resolved.conf
    systemctl restart systemd-resolved 2>/dev/null || true
    restored=1
    echo -e "  ${GREEN}${CHECKMARK}${NC} systemd-resolved config restored."
  fi

  if [[ -d "$SPLIT_CONF_DIR" ]]; then
    local split_files
    split_files=$(ls "${SPLIT_CONF_DIR}"/acor1-split-*.conf 2>/dev/null | wc -l || echo 0)
    if (( split_files > 0 )); then
      rm -f "${SPLIT_CONF_DIR}"/acor1-split-*.conf
      systemctl restart systemd-resolved 2>/dev/null || true
      restored=1
      echo -e "  ${GREEN}${CHECKMARK}${NC} Removed $split_files split DNS config(s)."
    fi
  fi

  if [[ $restored -eq 0 ]]; then
    echo -e "  ${YELLOW}⚠ No backup found.${NC}"
  else
    log_dns_change "Restore" "original" "backup"
  fi
}

custom_dns() {
  print_title "🛠  Custom DNS Setup"
  local dns1 dns2
  while true; do
    read -rp "  Primary DNS:   " dns1
    validate_ip "$dns1" && break
    echo -e "  ${RED}❌ Invalid IP.${NC}"
  done
  while true; do
    read -rp "  Secondary DNS: " dns2
    validate_ip "$dns2" && break
    echo -e "  ${RED}❌ Invalid IP.${NC}"
  done
  apply_dns "$dns1" "$dns2" "Custom"
}

show_current_dns() {
  print_title "🔎 Current DNS Settings"

  if [[ $HAS_RESOLVECTL -eq 1 ]]; then
    resolvectl status 2>/dev/null | head -30 | sed 's/^/  /' || true
  else
    if [[ -f /etc/resolv.conf ]]; then
      grep -E '^nameserver' /etc/resolv.conf 2>/dev/null | sed 's/^/  /' || \
        echo -e "  ${YELLOW}No nameservers found.${NC}"
    fi
  fi

  if [[ -f "$LAST_DNS_FILE" ]]; then
    echo
    echo -e "  ${DIM}Last applied by acor1:${NC}"
    IFS='|' read -r name d1 d2 < "$LAST_DNS_FILE"
    echo -e "  ${GREEN}$name${NC} → $d1, $d2"
  fi

  local resolved_status
  if [[ $HAS_RESOLVED -eq 1 ]]; then
    resolved_status="yes (systemd v${RESOLVED_VERSION})"
  else
    resolved_status="no"
  fi

  local dot_status
  if supports_dot; then
    dot_status="yes"
  else
    dot_status="no"
  fi

  echo
  echo -e "  ${DIM}System:      ${WHITE}$(lsb_release -ds 2>/dev/null || grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || echo Unknown)${NC}"
  echo -e "  ${DIM}Init:        ${WHITE}$([[ $HAS_SYSTEMD -eq 1 ]] && echo systemd || echo sysvinit)${NC}"
  echo -e "  ${DIM}Systemd:     ${WHITE}v${SYSTEMD_VERSION}${NC}"
  echo -e "  ${DIM}Resolved:    ${WHITE}${resolved_status}${NC}"
  echo -e "  ${DIM}DoT support: ${WHITE}${dot_status}${NC}"
}

if [[ "${1:-}" == "--restore" ]]; then
  restore_dns
  exit 0
fi

SKIP_DEPS=0
if [[ "${1:-}" == "--no-deps" ]]; then
  SKIP_DEPS=1
fi

main_menu() {
  print_header
  while true; do
    echo
    echo -e "${CYAN}${BOLD}  ══════════════════════════════════════════${NC}"
    echo -e "${CYAN}${BOLD}                 🧭  DNS OPTIONS${NC}"
    echo -e "${CYAN}${BOLD}  ══════════════════════════════════════════${NC}"
    echo
    echo -e "    ${GREEN}${BOLD}[1]${NC}   Quick Apply — Google DNS"
    echo -e "    ${GREEN}${BOLD}[2]${NC}   Quick Apply — Cloudflare DNS"
    echo -e "    ${GREEN}${BOLD}[3]${NC}   Quick Apply — Quad9 DNS"
    echo -e "    ${GREEN}${BOLD}[4]${NC}   Quick Apply — Shecan DNS   ${DIM}(IR)${NC}"
    echo -e "    ${GREEN}${BOLD}[5]${NC}   Quick Apply — 403 DNS      ${DIM}(IR)${NC}"
    echo -e "    ${YELLOW}${BOLD}[6]${NC}   Custom DNS"
    echo -e "    ${PURPLE}${BOLD}[7]${NC}   ⚡ Smart Benchmark (real resolve)"
    echo -e "    ${BLUE}${BOLD}[8]${NC}   🔒 Encrypted DNS (DoT)"
    echo -e "    ${CYAN}${BOLD}[9]${NC}   🎯 Split DNS (domain-specific)"
    echo -e "    ${WHITE}${BOLD}[10]${NC}  🔍 DNS Leak Test"
    echo -e "    ${WHITE}${BOLD}[11]${NC}  📊 Cache Statistics"
    echo -e "    ${WHITE}${BOLD}[12]${NC}  🕒 Change History"
    echo -e "    ${WHITE}${BOLD}[13]${NC}  🔎 Show Current DNS"
    echo -e "    ${BLUE}${BOLD}[14]${NC}  ♻️  Restore Backup"
    echo -e "    ${RED}${BOLD}[0]${NC}   Exit"
    echo
    echo -e "${CYAN}${BOLD}  ══════════════════════════════════════════${NC}"
    echo
    printf "${PURPLE}${BOLD}  ➤ Select an option: ${NC}"
    read -r choice

    case $choice in
      1)  apply_dns 8.8.8.8 8.8.4.4 "Google DNS" ;;
      2)  apply_dns 1.1.1.1 1.0.0.1 "Cloudflare DNS" ;;
      3)  apply_dns 9.9.9.9 149.112.112.112 "Quad9 DNS" ;;
      4)  apply_dns 178.22.122.100 185.51.200.2 "Shecan DNS" ;;
      5)  apply_dns 10.202.10.202 10.202.10.102 "403 DNS" ;;
      6)  custom_dns ;;
      7)  smart_benchmark ;;
      8)  dot_menu ;;
      9)  split_dns ;;
      10) leak_test ;;
      11) cache_stats ;;
      12) show_history ;;
      13) show_current_dns ;;
      14) restore_dns ;;
      0)
        echo -e "\n  ${GREEN}${BOLD}👋 Goodbye! Thanks for using acor1.${NC}"
        sleep 0.6
        clear
        exit 0
        ;;
      *)
        echo -e "  ${RED}❌ Invalid option. Try again.${NC}"
        ;;
    esac
  done
}

if [[ $SKIP_DEPS -eq 0 ]]; then
  install_dependencies
fi
main_menu
