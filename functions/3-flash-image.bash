flash-image() {
  echo "[*] Writing image to $SDDEV ..."

  # Write image (supports .xz or raw)
  if [[ "$IMAGE" == *.xz ]]; then
      sudo xzcat "$IMAGE" | sudo dd of="$SDDEV" bs=4M status=progress conv=fsync
  else
      sudo dd if="$IMAGE" of="$SDDEV" bs=4M status=progress conv=fsync
  fi

  echo "[*] Syncing writes..."
  sync
  sudo udevadm settle
  sleep 1

  echo "[*] Forcing partition table refresh..."
  sudo partprobe "$SDDEV" || true
  sudo blockdev --rereadpt "$SDDEV" || true
  sudo udevadm settle
  sleep 1

  # --- USB re-enumeration (important for flaky readers) ---
  DEV_NAME=$(basename "$SDDEV")
  USB_PATH=$(readlink -f /sys/block/"$DEV_NAME"/device | sed 's|/block/.*||')

  if [[ -f "$USB_PATH/authorized" ]]; then
    echo "[*] Resetting USB device (re-enumerate)..."
    echo 0 | sudo tee "$USB_PATH/authorized" >/dev/null
    sleep 1
    echo 1 | sudo tee "$USB_PATH/authorized" >/dev/null
    sudo udevadm settle
    sleep 2
  fi
  # -------------------------------------------------------

  echo "[*] Flash complete. Current partition view:"
  lsblk "$SDDEV"
}
