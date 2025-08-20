#!/bin/bash
set -euo pipefail

image() {
  echo "==== Raspberry Pi SD card preparation ===="

  # 1. Look for Raspberry Pi images
  IMG_DIR="$HOME/Downloads"
  IMAGES=($(find "$IMG_DIR" -maxdepth 1 -type f -name "*.img*" | sort))
  if [ ${#IMAGES[@]} -eq 0 ]; then
      echo "[!] No Raspberry Pi images found in $IMG_DIR"
      exit 1
  fi

  echo "[*] Found Raspberry Pi images:"
  for i in "${!IMAGES[@]}"; do
      echo "$((i+1))) ${IMAGES[$i]}"
  done
  read -rp "#? " IMG_SEL
  IMAGE="${IMAGES[$((IMG_SEL-1))]}"
  echo "Selected image: $IMAGE"
}
