#!/bin/bash
set -euo pipefail

new-user(){
  echo "==== Raspberry Pi SSH Setup ===="

  # --- 1)  Verificar que particiones estén montadas
  if [[ ! -d "${ROOT_MNT:-}" || ! -d "${BOOT_MNT:-}" ]]; then
    echo "[!] Boot or root partition not mounted."
    return 1
  fi

  # --- 2) Prompt new username & password ---
  while true; do
    read -rp "Enter new username: " NEWUSER
    [[ -n "$NEWUSER" ]] && break
  done

  while true; do
    read -rsp "Enter password for $NEWUSER: " PASS1; echo
    read -rsp "Confirm password: " PASS2; echo
    if [[ "$PASS1" == "$PASS2" ]]; then
      NEW_PASSWORD_HASH=$(openssl passwd -6 "$PASS1")
      break
    else
      echo "[!] Passwords do not match, try again."
    fi
  done

  # --- 3) Paths ---
  OLD_USER="pi"
  NEW_HOME="$ROOT_MNT/home/$NEWUSER"
  OLD_HOME="$ROOT_MNT/home/$OLD_USER"

  echo "[*] Creating new user $NEWUSER and copying configs from $OLD_USER"

  # --- 4) Create new home & copy configs from pi ---
  sudo mkdir -p "$NEW_HOME"
  sudo cp -a "$OLD_HOME/." "$NEW_HOME/" || true
  sudo chown -R 1000:1000 "$NEW_HOME"

  # --- 5) Add user to /etc/passwd and /etc/shadow ---
  echo "$NEWUSER:x:1000:1000:$NEWUSER:/home/$NEWUSER:/bin/bash" | sudo tee -a "$ROOT_MNT/etc/passwd" >/dev/null
  echo "$NEWUSER:$NEW_PASSWORD_HASH:18295:0:99999:7:::" | sudo tee -a "$ROOT_MNT/etc/shadow" >/dev/null
  sudo sed -i "/^$NEWUSER:/d" "$ROOT_MNT/etc/group"
  echo "$NEWUSER:x:1000:" | sudo tee -a "$ROOT_MNT/etc/group" >/dev/null

  # --- 6) Write userconf.txt for first boot ---
  echo "${NEWUSER}:${NEW_PASSWORD_HASH}" | sudo tee "$BOOT_MNT/userconf.txt" >/dev/null

  # --- 7) Remove default pi user completely ---
  sudo rm -rf "$OLD_HOME"
  sudo sed -i '/^pi:/d' "$ROOT_MNT/etc/passwd" "$ROOT_MNT/etc/shadow" "$ROOT_MNT/etc/group"

  # --- 8) Add new user to sudoers ---
  sudo sed -i "/^sudo:/ s/$/,$NEWUSER/" "$ROOT_MNT/etc/group"
  echo "$NEWUSER ALL=(ALL) NOPASSWD:ALL" | sudo tee "$ROOT_MNT/etc/sudoers.d/$NEWUSER" >/dev/null
  sudo chmod 440 "$ROOT_MNT/etc/sudoers.d/$NEWUSER"

  echo "[*] User $NEWUSER created, pi removed, sudoer done."

}