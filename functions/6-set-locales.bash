#!/bin/bash
set -euo pipefail

select-option() {
  local result_var="$1"
  local prompt="$2"
  shift 2
  local options=("$@")
  local selection

  while true; do
    echo "$prompt"
    for i in "${!options[@]}"; do
      echo "$((i + 1))) ${options[$i]}"
    done

    read -rp "Select an option: " selection
    if [[ "$selection" =~ ^[0-9]+$ ]] && (( selection >= 1 && selection <= ${#options[@]} )); then
      printf -v "$result_var" '%s' "${options[$((selection - 1))]}"
      return 0
    fi

    echo "[!] Invalid selection, try again."
  done
}

set-locale() {
  # 10. Locale, keyboard, timezone
  echo "[*] Configuring locales"

  local locale_options=(
    "en_US.UTF-8"
    "en_GB.UTF-8"
    "es_ES.UTF-8"
    "fr_FR.UTF-8"
    "de_DE.UTF-8"
    "it_IT.UTF-8"
    "pt_PT.UTF-8"
    "Custom"
  )
  local keymap_options=(
    "us"
    "uk"
    "es"
    "fr"
    "de"
    "it"
    "pt"
    "Custom"
  )
  local timezone_options=(
    "Europe/Madrid"
    "Europe/London"
    "Europe/Paris"
    "Europe/Berlin"
    "Europe/Rome"
    "Europe/Lisbon"
    "UTC"
    "Custom"
  )

  local selected_locale
  local selected_keymap
  local selected_timezone

  select-option selected_locale "[*] Available locales:" "${locale_options[@]}"
  if [[ "$selected_locale" == "Custom" ]]; then
    while true; do
      read -rp "Enter locale (example: en_US.UTF-8): " selected_locale
      [[ -n "$selected_locale" ]] && break
      echo "[!] Locale cannot be empty."
    done
  fi

  select-option selected_keymap "[*] Available keyboard layouts:" "${keymap_options[@]}"
  if [[ "$selected_keymap" == "Custom" ]]; then
    while true; do
      read -rp "Enter keymap (example: us): " selected_keymap
      [[ -n "$selected_keymap" ]] && break
      echo "[!] Keymap cannot be empty."
    done
  fi

  select-option selected_timezone "[*] Available timezones:" "${timezone_options[@]}"
  if [[ "$selected_timezone" == "Custom" ]]; then
    while true; do
      read -rp "Enter timezone (example: Europe/Madrid): " selected_timezone
      [[ -n "$selected_timezone" ]] && break
      echo "[!] Timezone cannot be empty."
    done
  fi

  sudo sed -i "s/^#\\(${selected_locale} UTF-8\\)/\\1/" "$ROOT_MNT/etc/locale.gen"
  if ! grep -q "^${selected_locale} UTF-8$" "$ROOT_MNT/etc/locale.gen"; then
    echo "${selected_locale} UTF-8" | sudo tee -a "$ROOT_MNT/etc/locale.gen" >/dev/null
  fi

  sudo tee "$ROOT_MNT/etc/locale.conf" >/dev/null <<<"LANG=${selected_locale}"
  sudo tee "$ROOT_MNT/etc/vconsole.conf" >/dev/null <<<"KEYMAP=${selected_keymap}"
  sudo tee "$ROOT_MNT/etc/default/keyboard" >/dev/null <<EOF
XKBMODEL="pc105"
XKBLAYOUT="${selected_keymap}"
XKBVARIANT=""
XKBOPTIONS=""
BACKSPACE="guess"
EOF
  sudo ln -sf "/usr/share/zoneinfo/${selected_timezone}" "$ROOT_MNT/etc/localtime"
  sudo tee "$ROOT_MNT/etc/timezone" >/dev/null <<<"${selected_timezone}"

}
