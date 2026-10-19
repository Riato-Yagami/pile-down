#!/usr/bin/env bash
set -euo pipefail

PILE_DOWN_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${PILE_DOWN_SCRIPT_DIR}/common.sh"
pile_down_prepare_build
pile_down_require_packager
PILE_DOWN_WEB_DIR="${PILE_DOWN_PLATFORMS_DIR}/web"
PILE_DOWN_ARCHIVE="${PILE_DOWN_WEB_DIR}/pile-down-web-${PILE_DOWN_VERSION}.zip"

mkdir -p "${PILE_DOWN_WEB_DIR}"
PILE_DOWN_GODOT_BIN="${PILE_DOWN_GODOT_BIN}" \
XDG_DATA_HOME="${PILE_DOWN_DATA_HOME}" \
	"${PILE_DOWN_SCRIPT_DIR}/ensure_export_templates.sh" web
XDG_DATA_HOME="${PILE_DOWN_DATA_HOME}" \
XDG_CONFIG_HOME="${PILE_DOWN_CONFIG_HOME}" \
	"${PILE_DOWN_GODOT_BIN}" \
	--headless \
	--path . \
	--export-release Web \
	"${PILE_DOWN_WEB_DIR}/index.html"

"${PILE_DOWN_PYTHON_BIN}" "${PILE_DOWN_SCRIPT_DIR}/package_archive.py" "${PILE_DOWN_ARCHIVE}" \
	"${PILE_DOWN_WEB_DIR}/index.html" \
	"${PILE_DOWN_WEB_DIR}/index.js" \
	"${PILE_DOWN_WEB_DIR}/index.wasm" \
	"${PILE_DOWN_WEB_DIR}/index.pck" \
	"${PILE_DOWN_WEB_DIR}/index.png" \
	"${PILE_DOWN_WEB_DIR}/index.icon.png" \
	"${PILE_DOWN_WEB_DIR}/index.apple-touch-icon.png" \
	"${PILE_DOWN_WEB_DIR}/index.audio.worklet.js" \
	"${PILE_DOWN_WEB_DIR}/index.audio.position.worklet.js"

echo "Web build ready: ${PILE_DOWN_ARCHIVE}"
