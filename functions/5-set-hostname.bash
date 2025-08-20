#!/bin/bash
set -euo pipefail

set-hostname() {
  # 6. Set hostname
  read -rp "[*] Enter hostname for the Pi: " HOSTNAME
  echo "$HOSTNAME" | sudo tee "$ROOT_MNT/etc/hostname" >/dev/null
  sudo sed -i "s/127.0.1.1.*$/127.0.1.1 $HOSTNAME/" "$ROOT_MNT/etc/hosts"
}