#!/bin/bash
set -euo pipefail

mount-partitions() {
  # 4. Mount partitions
  ROOT_MNT=$(mktemp -d)
  BOOT_MNT=$(mktemp -d)
  sudo mount "${SDDEV}2" "$ROOT_MNT"
  sudo mount "${SDDEV}1" "$BOOT_MNT"
  echo "[*] Rootfs: $ROOT_MNT"
  echo "[*] Bootfs: $BOOT_MNT"
}