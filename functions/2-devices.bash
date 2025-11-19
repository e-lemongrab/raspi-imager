#!/bin/bash
set -euo pipefail

devices() {
  echo "[*] Available removable devices:"
  mapfile -t DEVICES < <(lsblk -d -o NAME,SIZE,MODEL,RM | awk '$4==1 {print "/dev/"$1}')
  for i in "${!DEVICES[@]}"; do
      echo "$((i+1))) ${DEVICES[$i]}"
  done
  read -rp "Select target SD card device: " DEV_SEL
  SDDEV="${DEVICES[$((DEV_SEL-1))]}"
  echo "Selected device: $SDDEV"

  read -rp "WARNING: All data on $SDDEV will be erased. Continue? [y/N]: " CONF
  [[ "$CONF" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }

  # Unmount all partitions
  sudo umount "${SDDEV}"* 2>/dev/null || true

  echo "[*] Wiping first and last sectors..."
  sudo dd if=/dev/zero of="$SDDEV" bs=1M count=10 conv=fsync

  # ✅ FIXED: use sudo blockdev
  SIZE_MB=$(( $(sudo blockdev --getsize64 "$SDDEV") / 1048576 ))
  sudo dd if=/dev/zero of="$SDDEV" bs=1M seek=$((SIZE_MB - 10)) count=10 conv=fsync || true

  # ✅ Let kernel update view before imaging
  sudo partprobe "$SDDEV" || true
  sudo udevadm settle
}
