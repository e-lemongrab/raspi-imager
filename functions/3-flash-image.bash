#!/bin/bash
set -euo pipefail

flash-image() {
  echo "[*] Writing image to $SDDEV ..."

  if [[ "$IMAGE" == *.xz ]]; then
      sudo xzcat "$IMAGE" | sudo dd of="$SDDEV" bs=4M status=progress conv=fsync
  else
      sudo dd if="$IMAGE" of="$SDDEV" bs=4M status=progress conv=fsync
  fi

  sync
  echo "[*] Flashing complete."

  # 🔄 Tell the kernel to re-read the partition table
  sudo partprobe "$SDDEV" || true
  sleep 2  # give udev a moment to create /dev/sdf1, /dev/sdf2

  echo "[*] Partitions on $SDDEV:"
  lsblk "$SDDEV"
}
