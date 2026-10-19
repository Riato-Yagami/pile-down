#!/usr/bin/env bash
set -euo pipefail

PILE_DOWN_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${PILE_DOWN_SCRIPT_DIR}/common.sh"
pile_down_prepare_build
PILE_DOWN_ENGINE_VERSION="$("${PILE_DOWN_GODOT_BIN}" --version | tr -d '\r\n')"
# Official binaries append build metadata (.official.<hash> or .mono.official).
if [[ "${PILE_DOWN_ENGINE_VERSION}" =~ ^([0-9]+\.[0-9]+(\.[0-9]+)?)\.([a-z]+[0-9]*)(\.|$) ]]; then
	PILE_DOWN_TEMPLATE_VERSION="${BASH_REMATCH[1]}.${BASH_REMATCH[3]}"
	PILE_DOWN_RELEASE_VERSION="${BASH_REMATCH[1]}-${BASH_REMATCH[3]}"
else
	echo "Unrecognized Godot version: ${PILE_DOWN_ENGINE_VERSION}" >&2
	exit 1
fi
PILE_DOWN_TEMPLATE_DIR="${PILE_DOWN_TEMPLATE_ROOT}/${PILE_DOWN_TEMPLATE_VERSION}"
PILE_DOWN_DOWNLOAD_DIR="${PILE_DOWN_CACHE_DIR}/templates"
PILE_DOWN_TEMPLATE_ARCHIVE="${PILE_DOWN_TEMPLATE_ARCHIVE:-${PILE_DOWN_DOWNLOAD_DIR}/Godot_v${PILE_DOWN_RELEASE_VERSION}_export_templates.tpz}"
PILE_DOWN_TEMPLATE_URL="https://github.com/godotengine/godot-builds/releases/download/${PILE_DOWN_RELEASE_VERSION}/Godot_v${PILE_DOWN_RELEASE_VERSION}_export_templates.tpz"

declare -a PILE_DOWN_REQUIRED_TEMPLATES=()
if [[ $# -eq 0 ]]; then
	echo "Usage: $0 web|linux|windows|android|android-aab [...]" >&2
	exit 1
fi
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
		windows)
			PILE_DOWN_REQUIRED_TEMPLATES+=(
				"windows_debug_x86_64.exe"
				"windows_release_x86_64.exe"
			)
			;;
		android-aab)
			PILE_DOWN_REQUIRED_TEMPLATES+=("android_source.zip" "android_release.apk")
			;;
		android)
			PILE_DOWN_REQUIRED_TEMPLATES+=(
				"android_debug.apk"
				"android_release.apk"
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

command -v unzip >/dev/null || {
	echo "unzip is required to install Godot export templates." >&2
	exit 1
}

mkdir -p "${PILE_DOWN_DOWNLOAD_DIR}" "${PILE_DOWN_TEMPLATE_DIR}"
if [[ ! -f "${PILE_DOWN_TEMPLATE_ARCHIVE}" ]]; then
	command -v curl >/dev/null || {
		echo "curl is required to download Godot export templates." >&2
		exit 1
	}
	echo "Downloading Godot ${PILE_DOWN_TEMPLATE_VERSION} export templates..."
	curl -L --fail --retry 2 --connect-timeout 20 \
		-o "${PILE_DOWN_TEMPLATE_ARCHIVE}.part" \
		"${PILE_DOWN_TEMPLATE_URL}"
	unzip -tq "${PILE_DOWN_TEMPLATE_ARCHIVE}.part" >/dev/null
	mv -- "${PILE_DOWN_TEMPLATE_ARCHIVE}.part" "${PILE_DOWN_TEMPLATE_ARCHIVE}"
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
