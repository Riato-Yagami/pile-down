#!/usr/bin/env bash
set -euo pipefail

PILE_DOWN_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PILE_DOWN_PROJECT_DIR="$(cd -- "${PILE_DOWN_SCRIPT_DIR}/.." && pwd)"
PILE_DOWN_GODOT_BIN="${PILE_DOWN_GODOT_BIN:-godot}"
PILE_DOWN_DATA_HOME="${XDG_DATA_HOME:-${PILE_DOWN_PROJECT_DIR}/build/.godot_data}"
PILE_DOWN_CONFIG_HOME="${XDG_CONFIG_HOME:-${PILE_DOWN_PROJECT_DIR}/build/.godot_config}"
PILE_DOWN_VERSION="$(tr -d '[:space:]' < "${PILE_DOWN_PROJECT_DIR}/VERSION")"
PILE_DOWN_WEB_DIR="build/web"
PILE_DOWN_ARCHIVE="${PILE_DOWN_WEB_DIR}/pile-down-web-${PILE_DOWN_VERSION}.zip"

cd "${PILE_DOWN_PROJECT_DIR}"

if [[ -z "${PILE_DOWN_VERSION}" ]]; then
	echo "VERSION is empty." >&2
	exit 1
fi

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

zip -j -q -FS "${PILE_DOWN_ARCHIVE}" \
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
