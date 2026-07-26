#!/usr/bin/env bash
set -euo pipefail

PILE_DOWN_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PILE_DOWN_PROJECT_DIR="$(cd -- "${PILE_DOWN_SCRIPT_DIR}/.." && pwd)"
PILE_DOWN_GODOT_BIN="${PILE_DOWN_GODOT_BIN:-godot}"
PILE_DOWN_DATA_HOME="${XDG_DATA_HOME:-${PILE_DOWN_PROJECT_DIR}/build/.godot_data}"
PILE_DOWN_CONFIG_HOME="${XDG_CONFIG_HOME:-${PILE_DOWN_PROJECT_DIR}/build/.godot_config}"
PILE_DOWN_VERSION="$(tr -d '[:space:]' < "${PILE_DOWN_PROJECT_DIR}/VERSION")"
PILE_DOWN_ANDROID_DIR="build/android"
PILE_DOWN_APK="${PILE_DOWN_ANDROID_DIR}/pile-down-android-${PILE_DOWN_VERSION}.apk"
PILE_DOWN_ANDROID_EXPORT_MODE="${PILE_DOWN_ANDROID_EXPORT_MODE:-debug}"

cd "${PILE_DOWN_PROJECT_DIR}"

if [[ -z "${PILE_DOWN_VERSION}" ]]; then
	echo "VERSION is empty." >&2
	exit 1
fi

case "${PILE_DOWN_ANDROID_EXPORT_MODE}" in
	debug)
		PILE_DOWN_EXPORT_FLAG="--export-debug"
		PILE_DOWN_DEBUG_KEYSTORE="${PILE_DOWN_PROJECT_DIR}/build/.android/debug.keystore"
		if [[ ! -f "${PILE_DOWN_DEBUG_KEYSTORE}" ]]; then
			command -v keytool >/dev/null || {
				echo "keytool from OpenJDK 17 is required for the Android debug build." >&2
				exit 1
			}
			mkdir -p "$(dirname -- "${PILE_DOWN_DEBUG_KEYSTORE}")"
			keytool -keyalg RSA -genkeypair \
				-alias androiddebugkey \
				-keypass android \
				-keystore "${PILE_DOWN_DEBUG_KEYSTORE}" \
				-storepass android \
				-dname "CN=Android Debug,O=Android,C=US" \
				-validity 9999 \
				-deststoretype PKCS12 >/dev/null
		fi
		export GODOT_ANDROID_KEYSTORE_DEBUG_PATH="${PILE_DOWN_DEBUG_KEYSTORE}"
		export GODOT_ANDROID_KEYSTORE_DEBUG_USER="androiddebugkey"
		export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD="android"
		;;
	release)
		PILE_DOWN_EXPORT_FLAG="--export-release"
		: "${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:?Set GODOT_ANDROID_KEYSTORE_RELEASE_PATH for a release build.}"
		: "${GODOT_ANDROID_KEYSTORE_RELEASE_USER:?Set GODOT_ANDROID_KEYSTORE_RELEASE_USER for a release build.}"
		: "${GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD:?Set GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD for a release build.}"
		;;
	*)
		echo "PILE_DOWN_ANDROID_EXPORT_MODE must be 'debug' or 'release'." >&2
		exit 1
		;;
esac

mkdir -p "${PILE_DOWN_ANDROID_DIR}"
PILE_DOWN_GODOT_BIN="${PILE_DOWN_GODOT_BIN}" \
XDG_DATA_HOME="${PILE_DOWN_DATA_HOME}" \
	"${PILE_DOWN_SCRIPT_DIR}/ensure_export_templates.sh" android
XDG_DATA_HOME="${PILE_DOWN_DATA_HOME}" \
XDG_CONFIG_HOME="${PILE_DOWN_CONFIG_HOME}" \
	"${PILE_DOWN_GODOT_BIN}" \
	--headless \
	--path . \
	"${PILE_DOWN_EXPORT_FLAG}" Android \
	"${PILE_DOWN_APK}"

echo "Android ${PILE_DOWN_ANDROID_EXPORT_MODE} build ready: ${PILE_DOWN_APK}"
