#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# Settings. The Pi4 target user is hardcoded to pi.
# Arguments: <version|version-code> <target-pi4-ip>
# ------------------------------------------------------------------------------
TARGET_USER="pi"
TARGET_APP_DIR="/opt/rack_sense"
ARTIFACTS_DIR="artifacts"
DESKTOP_FILE="/home/pi/Desktop/rack_sense.desktop"
# ------------------------------------------------------------------------------

VERSION_INPUT="${1:-}"
TARGET_HOST="${2:-}"

if [ -z "$VERSION_INPUT" ] || [ -z "$TARGET_HOST" ]; then
  echo "Usage: $(basename "$0") <version|version-code> <target-pi4-ip>" >&2
  echo "Example: $(basename "$0") 0.1.0+1 192.168.0.71" >&2
  exit 1
fi

# Stage 1: Check artifact bundle and confirm zip exists
# ------------------------------------------------------------------------------
echo "=== Stage 1: Check artifact bundle ==="
BUNDLE_PATH=""
BUNDLE_NAME=""
if [ -f "$VERSION_INPUT" ]; then
  BUNDLE_PATH="$VERSION_INPUT"
  BUNDLE_NAME=$(basename "$BUNDLE_PATH")
elif BUNDLE_PATH=$(ls -t "${ARTIFACTS_DIR}/rack_sense_v${VERSION_INPUT}.zip" 2>/dev/null | head -n1) && [ -f "$BUNDLE_PATH" ]; then
  BUNDLE_NAME=$(basename "$BUNDLE_PATH")
elif BUNDLE_PATH=$(ls -t "${ARTIFACTS_DIR}/rack_sense_v${VERSION_INPUT}"*.zip 2>/dev/null | head -n1) && [ -f "$BUNDLE_PATH" ]; then
  BUNDLE_NAME=$(basename "$BUNDLE_PATH")
elif BUNDLE_PATH=$(ls -t "${ARTIFACTS_DIR}/rack_sense_v"*"+${VERSION_INPUT}.zip" 2>/dev/null | head -n1) && [ -f "$BUNDLE_PATH" ]; then
  BUNDLE_NAME=$(basename "$BUNDLE_PATH")
else
  echo "Error: No bundle found for '${VERSION_INPUT}' in ${ARTIFACTS_DIR}" >&2
  exit 1
fi

echo "Bundle: ${BUNDLE_PATH}"

# Stage 2: Kill any running rack_sense on target
# ------------------------------------------------------------------------------
echo "=== Stage 2: Kill rack_sense on target ==="
ssh "${TARGET_USER}@${TARGET_HOST}" 'sudo pkill -f rack_sense || true'

# Stage 3: Remove the application folder on target
# ------------------------------------------------------------------------------
echo "=== Stage 3: Remove target application folder ==="
ssh "${TARGET_USER}@${TARGET_HOST}" "sudo rm -rf ${TARGET_APP_DIR}"

# Stage 4: Recreate folder and adjust permissions (pi owner)
# ------------------------------------------------------------------------------
echo "=== Stage 4: Recreate folder and set permissions ==="
ssh "${TARGET_USER}@${TARGET_HOST}" bash -l -s -- "$TARGET_APP_DIR" <<'REMOTE'
set -e
TARGET_APP_DIR="$1"
sudo mkdir -p "$TARGET_APP_DIR"
sudo chown pi:pi "$TARGET_APP_DIR"
sudo chmod 755 "$TARGET_APP_DIR"
REMOTE

# Stage 5: Copy bundle zip to target
# ------------------------------------------------------------------------------
echo "=== Stage 5: Copy bundle to target ==="
scp "$BUNDLE_PATH" "${TARGET_USER}@${TARGET_HOST}:/tmp/rack_sense_bundle.zip"

# Stage 6: Extract bundle to application folder
# ------------------------------------------------------------------------------
echo "=== Stage 6: Extract bundle ==="
ssh "${TARGET_USER}@${TARGET_HOST}" bash -l -s -- "$TARGET_APP_DIR" <<'REMOTE'
set -e
TARGET_APP_DIR="$1"
unzip -o /tmp/rack_sense_bundle.zip -d "$TARGET_APP_DIR"
REMOTE

# Stage 7: Check/reset permissions on extracted bundle
# ------------------------------------------------------------------------------
echo "=== Stage 7: Check permissions ==="
ssh "${TARGET_USER}@${TARGET_HOST}" bash -l -s -- "$TARGET_APP_DIR" <<'REMOTE'
set -e
TARGET_APP_DIR="$1"
chmod -R 755 "$TARGET_APP_DIR"
chmod +x "$TARGET_APP_DIR/rack_sense"
REMOTE

# Stage 8: Create desktop shortcut if missing
# ------------------------------------------------------------------------------
echo "=== Stage 8: Create desktop shortcut ==="
ssh "${TARGET_USER}@${TARGET_HOST}" bash -l -s -- "$TARGET_APP_DIR" <<'REMOTE'
set -e
TARGET_APP_DIR="$1"
DESKTOP_FILE="/home/pi/Desktop/rack_sense.desktop"

if [ ! -f "$DESKTOP_FILE" ]; then
  cat > "$DESKTOP_FILE" <<'EOF'
[Desktop Entry]
Name=RackSense
Comment=Elmosis RackSense Controller
Exec=/opt/rack_sense/rack_sense
Path=/opt/rack_sense
Type=Application
Terminal=false
EOF
  chmod +x "$DESKTOP_FILE"
  echo "Desktop shortcut created."
else
  echo "Desktop shortcut already exists."
fi
REMOTE

echo "Deployment complete: ${TARGET_USER}@${TARGET_HOST}:${TARGET_APP_DIR}"
