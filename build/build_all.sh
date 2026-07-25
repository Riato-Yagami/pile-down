#!/usr/bin/env bash
set -euo pipefail

PILE_DOWN_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

"${PILE_DOWN_SCRIPT_DIR}/build_web.sh"
"${PILE_DOWN_SCRIPT_DIR}/build_linux.sh"

echo "All Pile Down builds are ready."
