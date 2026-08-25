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
- Optionally writes a static IPv4 for `eth0` as a NetworkManager keyfile
- Cleans up and unmounts partitions at the end

Two results of this are worth knowing before you boot the card:

- The new user gets **passwordless sudo** (`NOPASSWD:ALL`), and `sshd_config` is replaced with a key-only configuration (`PasswordAuthentication no`). The password you choose during setup works on the console and nowhere else.
- The `resize2fs_once` first-boot service is removed, so **the root filesystem is never expanded** to fill the card. The Pi keeps the image's original rootfs size.

## Static IPv4 (optional)

The last interactive step offers to write `/etc/NetworkManager/system-connections/eth0-static.nmconnection`
into the image, so the Pi boots with a fixed address instead of asking for a
DHCP lease. Answering `N` leaves `eth0` on DHCP, which is the previous
behaviour.

Why it is worth saying yes: a DHCP lease is a dependency that fails at the
worst moment. On 2026-08-25 a 2-second carrier flap left one k3s master **17
minutes** without an address - NetworkManager cancels the DHCP transaction when
carrier drops and retries with a growing backoff, so the outage outlived its
cause by three orders of magnitude. A MAC reservation in the router does not
help: the reservation lives in the router, and the host still has to be granted
the lease.

Keep the router's MAC reservation anyway, so the address is never handed to
another device.

Assumes a NetworkManager-based image (Raspberry Pi OS Bookworm or newer). On
older images that still use `dhcpcd`, the keyfile is ignored and the Pi stays
on DHCP.

## Scope

This repository is intended to prepare Raspberry Pi OS images offline on a microSD card already inserted into the Linux machine running the script.

It is not designed to modify the host desktop or laptop system, although it does rely on host tools such as `sudo`, `dd`, `mount`, `lsblk`, and `openssl`.

All changes are written directly to the mounted partitions. The script never chroots into the image.

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
- Device selection is barely validated. Text or an out-of-range number aborts safely, but entering `0` becomes a negative array index and silently selects the **last** device in the list. The confirmation screen showing path, size, model, and serial is your only check — read it
- This project is built for a direct personal workflow, not for every Raspberry Pi OS variant
- If the base image layout changes, some operations may stop working

## Current Status

The repository is functional for the author's target workflow, but it still includes assumptions about the environment and the base image. Reasonable future improvements:

- Stricter validation before modifying users and SSH settings
- Compatibility notes by Raspberry Pi OS version

## License

This project is distributed under the MIT License. See [LICENSE](LICENSE).
