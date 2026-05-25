#!/usr/bin/env bash
# Build the app (debug) and immediately launch it.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"${SCRIPT_DIR}/build-app.sh" debug
open "$(cd "${SCRIPT_DIR}/.." && pwd)/build/Debug/Rmbg.app"
