#!/bin/bash
set -euo pipefail

devices() {
  # 2. List removable devices
  echo "[*] Available removable devices:"
  mapfile -t DEVICES < <(lsblk -d -o NAME,SIZE,MODEL,RM | awk '$4==1 {print "/dev/"$1}')
  for i in "${!DEVICES[@]}"; do
      echo "$((i+1))) ${DEVICES[$i]}"
  done
  read -rp "Select target SD card device: " DEV_SEL
  SDDEV="${DEVICES[$((DEV_SEL-1))]}"
  echo "Selected device: $SDDEV"

  # 2a. Confirm format
  read -rp "WARNING: All data on $SDDEV will be erased. Continue? [y/N]: " CONF
  if [[ "$CONF" != "y" && "$CONF" != "Y" ]]; then
      echo "Aborted."
      exit 1
  fi

  # 2b. Unmount if mounted
  sudo umount "${SDDEV}"* || true

  # 2c. Wipe start and end
  sudo dd if=/dev/zero of="$SDDEV" bs=1M count=10 conv=fsync
  sudo dd if=/dev/zero of="$SDDEV" bs=1M seek=$(($(blockdev --getsize64 "$SDDEV")/1048576 - 10)) count=10 conv=fsync || true
}