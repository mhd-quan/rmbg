#!/usr/bin/env bash
# Build the SPM executable and wrap it into a proper macOS .app bundle.
# Usage:
#   ./Scripts/build-app.sh              # debug build → build/Debug/Rmbg.app
#   ./Scripts/build-app.sh release      # release build → build/Release/Rmbg.app
set -euo pipefail

CONFIG="${1:-debug}"
case "${CONFIG}" in
  debug|Debug)    SWIFT_CONFIG="debug";    OUT_DIR="Debug"   ;;
  release|Release) SWIFT_CONFIG="release"; OUT_DIR="Release" ;;
  *) echo "Unknown config: ${CONFIG} (expected debug or release)" >&2; exit 2 ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT}"

BIN_DIR=".build/${SWIFT_CONFIG}"
APP_DIR="build/${OUT_DIR}/Rmbg.app"
CONTENTS="${APP_DIR}/Contents"
MACOS="${CONTENTS}/MacOS"
RESOURCES="${CONTENTS}/Resources"

echo "==> Compiling Rmbg (${SWIFT_CONFIG})"
swift build -c "${SWIFT_CONFIG}"

echo "==> Assembling ${APP_DIR}"
rm -rf "${APP_DIR}"
mkdir -p "${MACOS}" "${RESOURCES}"

# Copy main executable
cp "${BIN_DIR}/Rmbg" "${MACOS}/Rmbg"
chmod +x "${MACOS}/Rmbg"

# Copy compiled asset catalog bundle (SwiftPM emits Rmbg_Rmbg.bundle when
# `resources: [.process("...")]` is used on a target that doesn't match its
# package name; otherwise the bundle is named Rmbg_Rmbg.bundle).
if [[ -d "${BIN_DIR}/Rmbg_Rmbg.bundle" ]]; then
  cp -R "${BIN_DIR}/Rmbg_Rmbg.bundle" "${RESOURCES}/"
fi

# Info.plist
cp "Sources/Rmbg/Resources/Info.plist" "${CONTENTS}/Info.plist"

# Touch the bundle so Finder/LaunchServices refresh
touch "${APP_DIR}"

echo "==> Built ${APP_DIR}"
echo "Run with: open '${APP_DIR}'"
