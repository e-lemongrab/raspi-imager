#!/bin/bash
set -euo pipefail

devices() {
  echo "[*] Available removable devices:"
  mapfile -t DEVICES < <(lsblk -d -n -o NAME,RM | awk '$2==1 {print "/dev/"$1}')
  for i in "${!DEVICES[@]}"; do
      echo "$((i+1))) ${DEVICES[$i]}"
  done
  read -rp "Select target SD card device: " DEV_SEL
  SDDEV="${DEVICES[$((DEV_SEL-1))]}"

  # Show detailed device info for verification
  DEV_SIZE_MB=$(sudo blockdev --getsize64 "$SDDEV" 2>/dev/null | awk '{printf "%.0f MB (%.2f GB)", $1/1048576, $1/1073741824}')
  DEV_MODEL=$(lsblk -d -n -o MODEL "$SDDEV" 2>/dev/null || echo "Unknown")
  DEV_SERIAL=$(lsblk -d -n -o SERIAL "$SDDEV" 2>/dev/null || echo "Unknown")

  echo ""
  echo "==== Device Details ===="
  echo "  Path:     $SDDEV"
  echo "  Size:     $DEV_SIZE_MB"
  echo "  Model:    $DEV_MODEL"
  echo "  Serial:   $DEV_SERIAL"
  echo "========================="

  read -rp "WARNING: All data on $SDDEV will be erased. Type 'YES' to continue: " CONF
  [[ "$CONF" == "YES" ]] || { echo "Aborted."; exit 1; }

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
