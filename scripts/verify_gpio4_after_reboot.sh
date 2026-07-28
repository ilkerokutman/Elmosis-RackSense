#!/usr/bin/env bash
set -euo pipefail

if ! command -v gpioinfo >/dev/null 2>&1; then
  echo "gpioinfo is unavailable. Install it with: sudo apt install gpiod" >&2
  exit 1
fi

matches=$(gpioinfo | grep -iE 'line[[:space:]]+4:|GPIO4|gpio-4' || true)

if [ -z "$matches" ]; then
  echo "GPIO 4 was not found in gpioinfo output." >&2
  exit 1
fi

echo "$matches"

if echo "$matches" | grep -qiE 'w1|1-wire'; then
  echo "GPIO 4 is still claimed by the 1-Wire service." >&2
  exit 1
fi

if echo "$matches" | grep -qi 'used'; then
  echo "GPIO 4 is in use by another consumer." >&2
  exit 1
fi

echo "GPIO 4 is available for RackSense."
