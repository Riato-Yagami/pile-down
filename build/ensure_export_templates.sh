#!/usr/bin/env bash
set -euo pipefail

PILE_DOWN_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PILE_DOWN_PROJECT_DIR="$(cd -- "${PILE_DOWN_SCRIPT_DIR}/.." && pwd)"
PILE_DOWN_GODOT_BIN="${PILE_DOWN_GODOT_BIN:-godot}"
PILE_DOWN_DATA_HOME="${XDG_DATA_HOME:-${PILE_DOWN_PROJECT_DIR}/build/.godot_data}"
PILE_DOWN_ENGINE_VERSION="$("${PILE_DOWN_GODOT_BIN}" --version)"
PILE_DOWN_TEMPLATE_VERSION="${PILE_DOWN_ENGINE_VERSION%%.arch_*}"
PILE_DOWN_RELEASE_VERSION="${PILE_DOWN_TEMPLATE_VERSION%.stable}-stable"
PILE_DOWN_TEMPLATE_DIR="${PILE_DOWN_DATA_HOME}/godot/export_templates/${PILE_DOWN_TEMPLATE_VERSION}"
PILE_DOWN_CACHE_DIR="${PILE_DOWN_PROJECT_DIR}/build/.template_cache"
PILE_DOWN_TEMPLATE_ARCHIVE="${PILE_DOWN_CACHE_DIR}/Godot_v${PILE_DOWN_RELEASE_VERSION}_export_templates.tpz"
PILE_DOWN_TEMPLATE_URL="https://github.com/godotengine/godot-builds/releases/download/${PILE_DOWN_RELEASE_VERSION}/Godot_v${PILE_DOWN_RELEASE_VERSION}_export_templates.tpz"

declare -a PILE_DOWN_REQUIRED_TEMPLATES=()
for PILE_DOWN_PLATFORM in "$@"; do
	case "${PILE_DOWN_PLATFORM}" in
		web)
			PILE_DOWN_REQUIRED_TEMPLATES+=(
				"web_nothreads_debug.zip"
				"web_nothreads_release.zip"
			)
			;;
		linux)
			PILE_DOWN_REQUIRED_TEMPLATES+=(
				"linux_debug.x86_64"
				"linux_release.x86_64"
			)
			;;
		*)
			echo "Unknown export-template platform: ${PILE_DOWN_PLATFORM}" >&2
			exit 1
			;;
	esac
done

PILE_DOWN_MISSING=false
for PILE_DOWN_TEMPLATE in "${PILE_DOWN_REQUIRED_TEMPLATES[@]}"; do
	if [[ ! -f "${PILE_DOWN_TEMPLATE_DIR}/${PILE_DOWN_TEMPLATE}" ]]; then
		PILE_DOWN_MISSING=true
		break
	fi
done

if [[ "${PILE_DOWN_MISSING}" == false ]]; then
	exit 0
fi

command -v curl >/dev/null || {
	echo "curl is required to download Godot export templates." >&2
	exit 1
}
command -v unzip >/dev/null || {
	echo "unzip is required to install Godot export templates." >&2
	exit 1
}

mkdir -p "${PILE_DOWN_CACHE_DIR}" "${PILE_DOWN_TEMPLATE_DIR}"
if [[ ! -f "${PILE_DOWN_TEMPLATE_ARCHIVE}" ]]; then
	echo "Downloading Godot ${PILE_DOWN_TEMPLATE_VERSION} export templates..."
	curl -L --fail --retry 2 \
		-o "${PILE_DOWN_TEMPLATE_ARCHIVE}" \
		"${PILE_DOWN_TEMPLATE_URL}"
fi

for PILE_DOWN_TEMPLATE in "${PILE_DOWN_REQUIRED_TEMPLATES[@]}"; do
	if [[ ! -f "${PILE_DOWN_TEMPLATE_DIR}/${PILE_DOWN_TEMPLATE}" ]]; then
		unzip -j -o \
			"${PILE_DOWN_TEMPLATE_ARCHIVE}" \
			"templates/${PILE_DOWN_TEMPLATE}" \
			-d "${PILE_DOWN_TEMPLATE_DIR}"
	fi
done

unzip -j -o \
	"${PILE_DOWN_TEMPLATE_ARCHIVE}" \
	"templates/version.txt" \
	-d "${PILE_DOWN_TEMPLATE_DIR}" >/dev/null
