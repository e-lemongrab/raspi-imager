#!/bin/bash
set -euo pipefail

cleanup() {
  echo "[*] Cleanup, unmount partitions and remove temporal folders"
  # 13. Cleanup
  sudo umount "$ROOT_MNT"
  sudo umount "$BOOT_MNT"
  rmdir "$ROOT_MNT" "$BOOT_MNT"

  echo "==== Done ===="
}