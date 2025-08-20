#!/bin/bash
set -euo pipefail

ssh() {
  echo "==== Raspberry Pi SSH Setup ===="

  sudo touch "$BOOT_MNT/ssh"
  sudo chmod 600 "$BOOT_MNT/ssh"

  # --- 1) Verificar que particiones estén montadas
  if [[ ! -d "${ROOT_MNT:-}" || ! -d "${BOOT_MNT:-}" ]]; then
    echo "[!] Boot or root partition not mounted."
    return 1
  fi

  # --- 2) Select SSH public key ---
  echo "[*] Available public keys in ~/.ssh:"
  mapfile -t KEYS < <(find "$HOME/.ssh" -maxdepth 1 -type f -name "*.pub")
  if [ ${#KEYS[@]} -eq 0 ]; then
      echo "[!] No SSH public keys found in ~/.ssh"
      return 1
  fi
  for i in "${!KEYS[@]}"; do
      echo "$((i+1))) ${KEYS[$i]}"
  done
  while true; do
      read -rp "Select key to add: " KEY_SEL
      if [[ "$KEY_SEL" =~ ^[0-9]+$ ]] && (( KEY_SEL >= 1 && KEY_SEL <= ${#KEYS[@]} )); then
          PUBKEY=$(cat "${KEYS[$((KEY_SEL-1))]}")
          break
      else
          echo "Invalid selection, try again."
      fi
  done

  # --- 3) Setup SSH directory and copy selected key ---
  SSH_DIR="$NEW_HOME/.ssh"
  sudo mkdir -p "$SSH_DIR"
  echo "$PUBKEY" | sudo tee "$SSH_DIR/authorized_keys" >/dev/null
  sudo chmod 700 "$SSH_DIR"
  sudo chmod 600 "$SSH_DIR/authorized_keys"
  sudo chown -R 1000:1000 "$NEW_HOME"

  # --- 4) Harden sshd_config ---
  sudo tee "$ROOT_MNT/etc/ssh/sshd_config" >/dev/null <<'EOF'
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
PermitRootLogin no
Subsystem sftp internal-sftp
EOF

  echo "[*] SSH locked to selected key."
}
