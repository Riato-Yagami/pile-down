#!/usr/bin/env bash
# Shared paths for Bash on Linux and Git Bash with native Windows Godot.
PILE_DOWN_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PILE_DOWN_PROJECT_DIR="$(cd -- "${PILE_DOWN_SCRIPT_DIR}/../.." && pwd)"
if [[ -f "${PILE_DOWN_PROJECT_DIR}/build/export.local.sh" ]]; then
	source "${PILE_DOWN_PROJECT_DIR}/build/export.local.sh"
fi
PILE_DOWN_GODOT_BIN="${PILE_DOWN_GODOT_BIN:-godot}"
PILE_DOWN_CACHE_DIR="${PILE_DOWN_PROJECT_DIR}/build/.cache"
PILE_DOWN_DATA_HOME="${XDG_DATA_HOME:-${PILE_DOWN_CACHE_DIR}/data}"
PILE_DOWN_CONFIG_HOME="${XDG_CONFIG_HOME:-${PILE_DOWN_CACHE_DIR}/config}"
export XDG_DATA_HOME="${PILE_DOWN_DATA_HOME}"
export XDG_CONFIG_HOME="${PILE_DOWN_CONFIG_HOME}"

case "$(uname -s)" in
	MINGW*|MSYS*|CYGWIN*)
		# Native Windows Godot ignores XDG and reads templates from APPDATA.
		export APPDATA="$(cygpath -m "${PILE_DOWN_CONFIG_HOME}")"
		PILE_DOWN_TEMPLATE_ROOT="${PILE_DOWN_CONFIG_HOME}/Godot/export_templates"
		PILE_DOWN_PYTHON_BIN="${PILE_DOWN_PYTHON_BIN:-python}"
		;;
	Darwin*)
		PILE_DOWN_TEMPLATE_ROOT="${HOME}/Library/Application Support/Godot/export_templates"
		;;
	*)
		PILE_DOWN_TEMPLATE_ROOT="${PILE_DOWN_DATA_HOME}/godot/export_templates"
		;;
esac
PILE_DOWN_PYTHON_BIN="${PILE_DOWN_PYTHON_BIN:-python3}"

pile_down_require_packager() {
	command -v "${PILE_DOWN_PYTHON_BIN}" >/dev/null || {
		echo "Python 3 is required to package builds. Set PILE_DOWN_PYTHON_BIN." >&2
		return 1
	}
}

pile_down_prepare_build() {
	cd "${PILE_DOWN_PROJECT_DIR}"
	PILE_DOWN_VERSION="$(tr -d '[:space:]' < VERSION)"
	if [[ ! "${PILE_DOWN_VERSION}" =~ ^[a-zA-Z0-9][a-zA-Z0-9._+-]*$ ]]; then
		echo "VERSION must contain a non-empty filename-safe version." >&2
		return 1
	fi
	PILE_DOWN_PLATFORMS_DIR="build/platforms"
	command -v "${PILE_DOWN_GODOT_BIN}" >/dev/null || {
		echo "Godot not found: ${PILE_DOWN_GODOT_BIN}. Set PILE_DOWN_GODOT_BIN." >&2
		return 1
	}
}
