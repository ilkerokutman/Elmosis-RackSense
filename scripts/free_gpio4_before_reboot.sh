#!/usr/bin/env bash
set -euo pipefail

if [ "${EUID}" -ne 0 ]; then
  echo "Run with sudo: sudo ./free_gpio4_before_reboot.sh" >&2
  exit 1
fi

config_file=""
for candidate in /boot/firmware/config.txt /boot/config.txt; do
  if [ -f "$candidate" ]; then
    config_file="$candidate"
    break
  fi
done

if [ -z "$config_file" ]; then
  echo "Raspberry Pi boot configuration was not found." >&2
  exit 1
fi

if grep -Eq '^[[:space:]]*dtoverlay=w1-gpio(,.*)?[[:space:]]*$' "$config_file"; then
  cp "$config_file" "${config_file}.rack_sense_backup"
  sed -i -E '/^[[:space:]]*dtoverlay=w1-gpio(,.*)?[[:space:]]*$/d' "$config_file"
  echo "Removed the w1-gpio overlay from ${config_file}."
else
  echo "No w1-gpio overlay is configured in ${config_file}."
fi

modprobe -r w1_therm w1_gpio 2>/dev/null || true

echo "GPIO 4 has been prepared for release."
echo "Reboot the Pi to apply the boot configuration change: sudo reboot"
