#!/bin/bash
set -euo pipefail

disable-services() {
  # --- 1) Disable WiFi and Bluetooth
  echo "[*] Disabling WiFi and Bt"
  echo "dtoverlay=disable-wifi" | sudo tee -a "$BOOT_MNT/config.txt" >/dev/null
  echo "dtoverlay=disable-bt"   | sudo tee -a "$BOOT_MNT/config.txt" >/dev/null

  # --- 2) Disable first boot wizard and unnecessary scripts ---
  sudo rm -f "$ROOT_MNT/etc/profile.d/sshpwd.sh"
  sudo rm -f "$ROOT_MNT/etc/systemd/system/multi-user.target.wants/raspberrypi-net-mods.service"
  sudo rm -f "$ROOT_MNT/etc/systemd/system/multi-user.target.wants/piwiz.service"
  sudo rm -f "$ROOT_MNT/etc/systemd/system/multi-user.target.wants/rc-local.service"
  sudo rm -f "$ROOT_MNT/etc/systemd/system/multi-user.target.wants/resize2fs_once.service"

}