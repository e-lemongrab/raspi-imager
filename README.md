# raspi-imager

Interactive Bash script to prepare a Raspberry Pi microSD card from an image stored in `~/Downloads`.

The workflow is intended for Linux and operates on the selected microSD card, not on the host desktop or laptop installation. It still writes directly to the chosen block device, so selecting the wrong device can destroy data.

## What It Does

- Detects `.img` and `.img.xz` images in `~/Downloads`
- Can download the latest official Raspberry Pi OS Lite (64-bit) image directly into `~/Downloads`
- Lists available removable devices so you can choose the target microSD card
- Flashes the image to the card
- Mounts the `boot` and `root` partitions
- Lets you set the hostname
- Configures locale, keyboard layout, and timezone inside the image through an interactive menu
- Creates a new user and removes the default `pi` user
- Enables SSH and adds a selected public key from `~/.ssh`
- Disables WiFi, Bluetooth, and some first-boot services
- Cleans up and unmounts partitions at the end

## Scope

This repository is intended to prepare Raspberry Pi OS images offline on a microSD card already inserted into the Linux machine running the script.

It is not designed to modify the host desktop or laptop system, although it does rely on host tools such as `sudo`, `dd`, `mount`, `lsblk`, `openssl`, and `chroot`.

## Requirements

- Linux
- Bash
- `sudo`
- `find`
- `grep`
- `lsblk`
- `awk`
- `curl` or `wget`
- `dd`
- `xzcat`
- `partprobe`
- `udevadm`
- `blockdev`
- `mount`
- `umount`
- `mktemp`
- `sed`
- `tee`
- `openssl`
- `chroot`

## Dependencies

On Debian/Ubuntu systems, the required utilities are usually provided by these packages:

- `bash`
- `coreutils`
- `findutils`
- `util-linux`
- `curl` or `wget`
- `xz-utils`
- `mount`
- `openssl`

## Compatibility

Expected compatibility:

- Linux host with `systemd`/`udev`
- Raspberry Pi OS images using the standard `boot` + `root` partition layout
- Images with partitions accessible as `${SDDEV}1` and `${SDDEV}2`
- Images that contain the expected `/etc` files for hostname, users, and SSH setup

Known limitations:

- Local images are expected in `~/Downloads`, and the script can also download the latest official Raspberry Pi OS Lite (64-bit) image there
- Locale, keyboard layout, and timezone are selected interactively from common presets or entered manually
- The workflow assumes a Raspberry Pi OS layout compatible with the files it edits
- The script does not handle every possible partition naming scheme or custom image layout
- It overwrites `sshd_config` inside the prepared image

## Usage

1. Copy a Raspberry Pi OS image into `~/Downloads`, or use the built-in option to download the latest official Raspberry Pi OS Lite (64-bit) image
2. Insert the microSD card into the Linux machine
3. Make sure you have at least one public key in `~/.ssh`
4. Run:

```bash
./core.bash
```

5. Select the detected image
6. Select the correct removable target device
7. Confirm device erasure
8. Enter the requested hostname, user, and other values

## Warnings

- The script erases the selected target device
- Verify the target device carefully before confirming
- This project is built for a direct personal workflow, not for every Raspberry Pi OS variant
- If the base image layout changes, some operations may stop working

## Current Status

The repository is functional for the author's target workflow, but it still includes assumptions about the environment and the base image. Reasonable future improvements:

- Stricter validation before modifying users and SSH settings
- Compatibility notes by Raspberry Pi OS version

## License

This project is distributed under the MIT License. See [LICENSE](LICENSE).
