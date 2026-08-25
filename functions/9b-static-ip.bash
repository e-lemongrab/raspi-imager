#!/bin/bash
set -euo pipefail

static-ip() {
  # Optional static IPv4 for eth0, written as a NetworkManager keyfile.
  #
  # Why this step exists: a Pi flashed without it boots on DHCP, and a DHCP
  # lease is a dependency that fails at the worst moment. On 2026-08-25 a
  # 2-second carrier flap left k3s-master01 17 minutes without an address -
  # NetworkManager cancels the DHCP transaction on carrier loss and retries
  # with a growing backoff, so the outage outlived the cause by three orders
  # of magnitude. A MAC reservation in the router does not help: the
  # reservation lives in the router, and the host still has to be granted
  # the lease. A static address survives the flap.
  #
  # Written straight into the image, so the Pi comes up correct on first
  # boot and is never reachable-only-by-luck.

  read -rp "[*] Configure a static IPv4 for eth0? [y/N]: " WANT_STATIC
  case "${WANT_STATIC,,}" in
    y|yes) ;;
    *) echo "[*] Leaving eth0 on DHCP"; return 0 ;;
  esac

  read -rp "[*] Address with prefix (e.g. 192.168.1.11/24): " IPV4_ADDR
  read -rp "[*] Gateway (e.g. 192.168.1.1): " IPV4_GW
  read -rp "[*] DNS servers, semicolon-separated (e.g. 192.168.1.5;192.168.1.6): " IPV4_DNS
  read -rp "[*] DNS search domain (blank for none): " IPV4_SEARCH

  if [[ -z "$IPV4_ADDR" || -z "$IPV4_GW" ]]; then
    echo "[!] Address and gateway are required - leaving eth0 on DHCP"
    return 0
  fi

  local NM_DIR="$ROOT_MNT/etc/NetworkManager/system-connections"
  local NM_FILE="$NM_DIR/eth0-static.nmconnection"
  sudo mkdir -p "$NM_DIR"

  {
    echo "[connection]"
    echo "id=eth0-static"
    echo "type=ethernet"
    echo "interface-name=eth0"
    echo "autoconnect=true"
    echo "autoconnect-retries=0"
    echo
    echo "[ipv4]"
    echo "method=manual"
    echo "address1=${IPV4_ADDR},${IPV4_GW}"
    [[ -n "$IPV4_DNS" ]] && echo "dns=${IPV4_DNS};"
    [[ -n "$IPV4_DNS" ]] && echo "ignore-auto-dns=true"
    [[ -n "$IPV4_SEARCH" ]] && echo "dns-search=${IPV4_SEARCH};"
    echo
    echo "[ipv6]"
    echo "method=disabled"
  } | sudo tee "$NM_FILE" >/dev/null

  # NetworkManager refuses to load a keyfile that others can read.
  sudo chmod 600 "$NM_FILE"
  sudo chown root:root "$NM_FILE"

  echo "[*] Wrote $NM_FILE ($IPV4_ADDR via $IPV4_GW)"
  echo "[*] Keep the router's MAC reservation for this address too, so it is"
  echo "    never handed out to another device."
}
