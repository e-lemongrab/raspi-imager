#!/bin/bash
set -euo pipefail

download-url() {
  local url="$1"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url"
    return 0
  fi

  if command -v wget >/dev/null 2>&1; then
    wget -qO- "$url"
    return 0
  fi

  echo "[!] curl or wget is required to download the latest Raspberry Pi OS image."
  return 1
}

download-file() {
  local url="$1"
  local output_path="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -fL "$url" -o "$output_path"
    return 0
  fi

  if command -v wget >/dev/null 2>&1; then
    wget -O "$output_path" "$url"
    return 0
  fi

  echo "[!] curl or wget is required to download the latest Raspberry Pi OS image."
  return 1
}

download-latest-image() {
  local base_url="https://downloads.raspberrypi.com/raspios_lite_arm64/images/"
  local latest_dir
  local latest_page
  local image_name
  local image_url
  local target_path

  echo "[*] Looking up the latest Raspberry Pi OS Lite (64-bit) image..."
  latest_dir="$(
    download-url "$base_url" |
      grep -oE 'raspios_lite_arm64-[0-9]{4}-[0-9]{2}-[0-9]{2}/' |
      sort -Vu |
      tail -n 1
  )"

  if [[ -z "$latest_dir" ]]; then
    echo "[!] Unable to determine the latest Raspberry Pi OS Lite (64-bit) directory."
    return 1
  fi

  latest_page="$(download-url "${base_url}${latest_dir}")"
  image_name="$(
    printf '%s\n' "$latest_page" |
      grep -oE 'href="[^"]+\.img\.xz"' |
      sed 's/^href="//; s/"$//' |
      head -n 1
  )"

  if [[ -z "$image_name" ]]; then
    echo "[!] Unable to find an image archive in ${base_url}${latest_dir}"
    return 1
  fi

  image_url="${base_url}${latest_dir}${image_name}"
  target_path="${IMG_DIR}/${image_name}"

  if [[ -f "$target_path" ]]; then
    echo "[*] Latest image already exists in ${IMG_DIR}: $image_name"
    IMAGE="$target_path"
    return 0
  fi

  echo "[*] Downloading $image_name to ${IMG_DIR}"
  download-file "$image_url" "$target_path"
  IMAGE="$target_path"
}

image() {
  echo "==== Raspberry Pi SD card preparation ===="

  # 1. Look for Raspberry Pi images
  IMG_DIR="$HOME/Downloads"
  mkdir -p "$IMG_DIR"
  mapfile -t IMAGES < <(find "$IMG_DIR" -maxdepth 1 -type f \( -name "*.img" -o -name "*.img.xz" \) | sort)

  echo "[*] Found Raspberry Pi images:"
  if [ ${#IMAGES[@]} -eq 0 ]; then
    echo "0) No local images found in $IMG_DIR"
  else
    for i in "${!IMAGES[@]}"; do
      echo "$((i + 1))) ${IMAGES[$i]}"
    done
  fi

  local download_option=$(( ${#IMAGES[@]} + 1 ))
  local img_sel

  echo "${download_option}) Download latest Raspberry Pi OS Lite (64-bit)"

  while true; do
    read -rp "#? " img_sel
    if [[ "$img_sel" =~ ^[0-9]+$ ]]; then
      if (( img_sel >= 1 && img_sel <= ${#IMAGES[@]} )); then
        IMAGE="${IMAGES[$((img_sel - 1))]}"
        break
      fi

      if (( img_sel == download_option )); then
        download-latest-image
        break
      fi
    fi

    echo "[!] Invalid selection, try again."
  done

  echo "Selected image: $IMAGE"
}
