#!/bin/bash
set -euo pipefail

set-locale() {
  # 10. Locale, keyboard, timezone
  echo "[*] Configuring locales"
  sudo sed -i 's/^#\(en_US.UTF-8 UTF-8\)/\1/' "$ROOT_MNT/etc/locale.gen"
  sudo tee "$ROOT_MNT/etc/locale.conf" >/dev/null <<<"LANG=en_US.UTF-8"
  sudo tee "$ROOT_MNT/etc/vconsole.conf" >/dev/null <<<"KEYMAP=es"
  sudo ln -sf /usr/share/zoneinfo/Europe/Madrid "$ROOT_MNT/etc/localtime"
  sudo tee "$ROOT_MNT/etc/timezone" >/dev/null <<<"Europe/Madrid"
}