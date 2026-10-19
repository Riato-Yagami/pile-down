#!/usr/bin/env bash
set -euo pipefail

PILE_DOWN_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${PILE_DOWN_SCRIPT_DIR}/common.sh"
pile_down_prepare_build
pile_down_require_packager
PILE_DOWN_WINDOWS_DIR="${PILE_DOWN_PLATFORMS_DIR}/windows"
PILE_DOWN_EXECUTABLE="${PILE_DOWN_WINDOWS_DIR}/pile-down.exe"
PILE_DOWN_ARCHIVE="${PILE_DOWN_WINDOWS_DIR}/pile-down-windows-${PILE_DOWN_VERSION}.zip"

mkdir -p "${PILE_DOWN_WINDOWS_DIR}"
PILE_DOWN_GODOT_BIN="${PILE_DOWN_GODOT_BIN}" \
XDG_DATA_HOME="${PILE_DOWN_DATA_HOME}" \
	"${PILE_DOWN_SCRIPT_DIR}/ensure_export_templates.sh" windows
XDG_DATA_HOME="${PILE_DOWN_DATA_HOME}" \
XDG_CONFIG_HOME="${PILE_DOWN_CONFIG_HOME}" \
	"${PILE_DOWN_GODOT_BIN}" \
	--headless \
	--path . \
	--export-release Windows \
	"${PILE_DOWN_EXECUTABLE}"

"${PILE_DOWN_PYTHON_BIN}" "${PILE_DOWN_SCRIPT_DIR}/package_archive.py" \
	--executable "${PILE_DOWN_ARCHIVE}" "${PILE_DOWN_EXECUTABLE}"

echo "Windows build ready: ${PILE_DOWN_ARCHIVE}"
