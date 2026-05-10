#!/bin/bash

# Source all files in the functions/ folder
for f in functions/*.bash; do
    [ -f "$f" ] && source "$f"
done

image
devices
flash-image
mount-partitions
set-hostname
set-locale
new-user
ssh
disable-services
cleanup
