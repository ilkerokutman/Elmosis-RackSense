#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# Settings. The Pi5 build user is hardcoded to pi.
# Build host and branch can be passed as arguments:
#   ./build.sh [branch] [build-host]
# ------------------------------------------------------------------------------
BUILD_USER="pi"
BRANCH="${1:-main}"
BUILD_HOST="${2:-192.168.0.70}"
REMOTE_URL="https://github.com/ilkerokutman/Elmosis-RackSense"
REMOTE_WORK_DIR="/home/pi/elmosis-racksense-build"
LOCAL_APP_DIR="RackSense"
ARTIFACTS_DIR="artifacts"
# ------------------------------------------------------------------------------

PUBSPEC="${LOCAL_APP_DIR}/pubspec.yaml"

if [[ ! -f "$PUBSPEC" ]]; then
  echo "Error: ${PUBSPEC} not found. Run this script from the repo root." >&2
  exit 1
fi

# ------------------------------------------------------------------------------
# Stage 1: Commit and push from macOS
# ------------------------------------------------------------------------------
echo "=== Stage 1: Commit and push from macOS ==="
git remote set-url origin "$REMOTE_URL"
git add -A
if ! git diff --cached --quiet; then
  git commit -m "Build: $(date '+%Y-%m-%d %H:%M:%S')"
fi
git push origin "$BRANCH"

# ------------------------------------------------------------------------------
# Stage 2: Fetch/pull on Pi5 build server
# ------------------------------------------------------------------------------
echo "=== Stage 2: Fetch/pull on Pi5 build server (${BUILD_HOST}) ==="
REMOTE_VERSION=$(
  ssh "${BUILD_USER}@${BUILD_HOST}" bash -l -s -- "$REMOTE_WORK_DIR" "$BRANCH" "$REMOTE_URL" "$LOCAL_APP_DIR" <<'REMOTE'
set -e
REMOTE_WORK_DIR="$1"
BRANCH="$2"
REMOTE_URL="$3"
LOCAL_APP_DIR="$4"

if [ -d "${REMOTE_WORK_DIR}/.git" ]; then
  cd "$REMOTE_WORK_DIR"
  git remote set-url origin "$REMOTE_URL"
  git fetch -q origin
  git checkout -q -f -B "$BRANCH" "origin/$BRANCH"
else
  rm -rf "$REMOTE_WORK_DIR"
  git clone -q --branch "$BRANCH" "$REMOTE_URL" "$REMOTE_WORK_DIR"
  cd "$REMOTE_WORK_DIR"
fi

grep '^version:' "${LOCAL_APP_DIR}/pubspec.yaml" | sed -E 's/^version: *//'
REMOTE
)

if [ -z "$REMOTE_VERSION" ]; then
  echo "Error: Could not read version from Pi5." >&2
  exit 1
fi

# ------------------------------------------------------------------------------
# Stage 3: Compare version code between macOS and Pi5
# ------------------------------------------------------------------------------
echo "=== Stage 3: Compare version code ==="
MAC_VERSION=$(grep '^version:' "$PUBSPEC" | sed -E 's/^version: *//')
MAC_VERSION_CODE=$(echo "$MAC_VERSION" | cut -d'+' -s -f2)
REMOTE_VERSION_CODE=$(echo "$REMOTE_VERSION" | cut -d'+' -s -f2)

echo "  macOS version:  ${MAC_VERSION} (code ${MAC_VERSION_CODE})"
echo "  Pi5 version:    ${REMOTE_VERSION} (code ${REMOTE_VERSION_CODE})"

if [ "${MAC_VERSION_CODE}" != "${REMOTE_VERSION_CODE}" ]; then
  echo "Error: Version code mismatch between macOS and Pi5." >&2
  exit 1
fi

# ------------------------------------------------------------------------------
# Stage 4: Run build (clean + pub get + release)
# ------------------------------------------------------------------------------
echo "=== Stage 4: Build on Pi5 ==="
ssh "${BUILD_USER}@${BUILD_HOST}" bash -l -s -- "$REMOTE_WORK_DIR" "$LOCAL_APP_DIR" <<'REMOTE'
set -e
REMOTE_WORK_DIR="$1"
LOCAL_APP_DIR="$2"

# Ensure Flutter is available in non-interactive SSH sessions.
if ! command -v flutter >/dev/null 2>&1; then
  for FLUTTER_DIR in "$HOME/flutter" "$HOME/development/flutter" "/usr/local/flutter" "/opt/flutter"; do
    if [ -d "${FLUTTER_DIR}/bin" ]; then
      export PATH="${FLUTTER_DIR}/bin:$PATH"
      break
    fi
  done
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "Error: flutter command not found on the build server." >&2
  exit 1
fi

cd "${REMOTE_WORK_DIR}/${LOCAL_APP_DIR}"
flutter clean
flutter pub get
flutter build linux --release
REMOTE

# ------------------------------------------------------------------------------
# Stage 5: Zip the build output bundle
# ------------------------------------------------------------------------------
echo "=== Stage 5: Zip build output bundle ==="
VERSION_NAME=$(echo "$REMOTE_VERSION" | cut -d'+' -f1)
VERSION_LABEL="${VERSION_NAME}"
[ -n "$REMOTE_VERSION_CODE" ] && VERSION_LABEL="${VERSION_NAME}+${REMOTE_VERSION_CODE}"
BUNDLE_NAME="rack_sense_v${VERSION_LABEL}.zip"

ssh "${BUILD_USER}@${BUILD_HOST}" bash -l -s -- "$REMOTE_WORK_DIR" "$LOCAL_APP_DIR" "$BUNDLE_NAME" <<'REMOTE'
set -e
REMOTE_WORK_DIR="$1"
LOCAL_APP_DIR="$2"
BUNDLE_NAME="$3"

ARCH=$(uname -m)
case "$ARCH" in
  aarch64) ARCH_DIR=arm64 ;;
  x86_64)  ARCH_DIR=x64  ;;
  *)       ARCH_DIR="$ARCH" ;;
esac

BUNDLE_DIR="${REMOTE_WORK_DIR}/${LOCAL_APP_DIR}/build/linux/${ARCH_DIR}/release/bundle"
cd "$BUNDLE_DIR"
zip -r "../../../${BUNDLE_NAME}" .
REMOTE

# ------------------------------------------------------------------------------
# Stage 6: Copy the bundle to macOS
# ------------------------------------------------------------------------------
echo "=== Stage 6: Copy bundle to macOS ==="
mkdir -p "$ARTIFACTS_DIR"

scp "${BUILD_USER}@${BUILD_HOST}:${REMOTE_WORK_DIR}/${LOCAL_APP_DIR}/build/linux/${BUNDLE_NAME}" \
    "${ARTIFACTS_DIR}/${BUNDLE_NAME}"

echo "Build complete: ${ARTIFACTS_DIR}/${BUNDLE_NAME}"
