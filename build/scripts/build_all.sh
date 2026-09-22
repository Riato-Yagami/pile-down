#!/usr/bin/env bash
set -euo pipefail

PILE_DOWN_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

"${PILE_DOWN_SCRIPT_DIR}/build_windows.sh"
"${PILE_DOWN_SCRIPT_DIR}/build_web.sh"
"${PILE_DOWN_SCRIPT_DIR}/build_linux.sh"
"${PILE_DOWN_SCRIPT_DIR}/build_android.sh"
"${PILE_DOWN_SCRIPT_DIR}/build_android_aab.sh"

echo "Pile Down Windows, Web, Linux, Android APK and Android AAB builds are ready."
