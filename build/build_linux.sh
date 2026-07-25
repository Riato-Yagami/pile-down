#!/usr/bin/env bash
set -euo pipefail

PILE_DOWN_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PILE_DOWN_PROJECT_DIR="$(cd -- "${PILE_DOWN_SCRIPT_DIR}/.." && pwd)"
PILE_DOWN_GODOT_BIN="${PILE_DOWN_GODOT_BIN:-godot}"
PILE_DOWN_DATA_HOME="${XDG_DATA_HOME:-${PILE_DOWN_PROJECT_DIR}/build/.godot_data}"
PILE_DOWN_CONFIG_HOME="${XDG_CONFIG_HOME:-${PILE_DOWN_PROJECT_DIR}/build/.godot_config}"
PILE_DOWN_VERSION="$(tr -d '[:space:]' < "${PILE_DOWN_PROJECT_DIR}/VERSION")"
PILE_DOWN_LINUX_DIR="build/linux"
PILE_DOWN_EXECUTABLE="${PILE_DOWN_LINUX_DIR}/pile-down.x86_64"
PILE_DOWN_ARCHIVE="${PILE_DOWN_LINUX_DIR}/pile-down-linux-${PILE_DOWN_VERSION}.zip"

cd "${PILE_DOWN_PROJECT_DIR}"

if [[ -z "${PILE_DOWN_VERSION}" ]]; then
	echo "VERSION is empty." >&2
	exit 1
fi

mkdir -p "${PILE_DOWN_LINUX_DIR}"
PILE_DOWN_GODOT_BIN="${PILE_DOWN_GODOT_BIN}" \
XDG_DATA_HOME="${PILE_DOWN_DATA_HOME}" \
	"${PILE_DOWN_SCRIPT_DIR}/ensure_export_templates.sh" linux
XDG_DATA_HOME="${PILE_DOWN_DATA_HOME}" \
XDG_CONFIG_HOME="${PILE_DOWN_CONFIG_HOME}" \
	"${PILE_DOWN_GODOT_BIN}" \
	--headless \
	--path . \
	--export-release Linux \
	"${PILE_DOWN_EXECUTABLE}"

zip -j -q -FS "${PILE_DOWN_ARCHIVE}" "${PILE_DOWN_EXECUTABLE}"

echo "Linux build ready: ${PILE_DOWN_ARCHIVE}"
