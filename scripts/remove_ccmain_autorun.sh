#!/usr/bin/env bash
set -euo pipefail

if [ "${EUID}" -ne 0 ]; then
  echo "Run with sudo: sudo ./remove_ccmain_autorun.sh" >&2
  exit 1
fi

pattern='cc[-_]?main|ccmain'
found=0

mapfile -t service_units < <(
  systemctl list-unit-files --type=service --no-legend |
    awk -v pattern="$pattern" 'tolower($1) ~ pattern { print $1 }'
)

for unit in "${service_units[@]}"; do
  [ -z "$unit" ] && continue
  systemctl disable "$unit" || true
  echo "Disabled service: $unit"
  found=1
done

for directory in /home/pi/.config/autostart /etc/xdg/autostart; do
  [ -d "$directory" ] || continue
  while IFS= read -r -d '' file; do
    case "$file" in
      *.disabled) continue ;;
    esac
    if grep -qiE "$pattern" "$file"; then
      mv "$file" "${file}.disabled"
      echo "Disabled autostart entry: $file"
      found=1
    fi
  done < <(find "$directory" -maxdepth 1 -type f -print0)
done

if [ -d /home/pi/.config/lxsession ]; then
  while IFS= read -r -d '' file; do
    if grep -qiE "$pattern" "$file"; then
      cp "$file" "${file}.rack_sense_backup"
      sed -i -E "/${pattern}/Id" "$file"
      echo "Removed LXSession autostart entry from: $file"
      found=1
    fi
  done < <(find /home/pi/.config/lxsession -type f -print0)
fi

if [ "$found" -eq 0 ]; then
  echo "No CC-Main autorun configuration was found."
else
  echo "CC-Main autorun has been disabled. Reboot or log out to apply it."
fi
