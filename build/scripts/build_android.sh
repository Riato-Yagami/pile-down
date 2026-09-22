#!/usr/bin/env bash
set -euo pipefail

PILE_DOWN_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${PILE_DOWN_SCRIPT_DIR}/common.sh"
pile_down_prepare_build

PILE_DOWN_ANDROID_FORMAT=apk
PILE_DOWN_ANDROID_PRESET=Android
PILE_DOWN_TEMPLATE_PLATFORM=android
declare -a PILE_DOWN_ANDROID_FLAGS=()
if [[ $# -eq 1 && "$1" == --aab ]]; then
	PILE_DOWN_ANDROID_FORMAT=aab
	PILE_DOWN_ANDROID_PRESET="Android AAB"
	PILE_DOWN_TEMPLATE_PLATFORM=android-aab
	PILE_DOWN_ANDROID_EXPORT_MODE=release
	# Preserve an existing Gradle project, including any local customization.
	if [[ ! -d "${PILE_DOWN_PROJECT_DIR}/android/build" ]]; then
		PILE_DOWN_ANDROID_FLAGS+=(--install-android-build-template)
	fi
elif [[ $# -ne 0 ]]; then
	echo "Usage: $0 [--aab]" >&2
	exit 1
fi

PILE_DOWN_DEFAULT_JAVA_HOME=/usr/lib/jvm/java-17-openjdk
PILE_DOWN_DEFAULT_ANDROID_SDK="${HOME}/Android/Sdk"
PILE_DOWN_WINDOWS=false
case "$(uname -s)" in
	MINGW*|MSYS*|CYGWIN*)
		PILE_DOWN_WINDOWS=true
		PILE_DOWN_DEFAULT_JAVA_HOME=""
		PILE_DOWN_DEFAULT_ANDROID_SDK="${LOCALAPPDATA:-${HOME}/AppData/Local}/Android/Sdk"
		;;
	Darwin*)
		PILE_DOWN_DEFAULT_JAVA_HOME="$(/usr/libexec/java_home -v 17 2>/dev/null || true)"
		PILE_DOWN_DEFAULT_ANDROID_SDK="${HOME}/Library/Android/sdk"
		;;
esac
PILE_DOWN_JAVA_HOME="${PILE_DOWN_JAVA_HOME:-${JAVA_HOME:-${PILE_DOWN_DEFAULT_JAVA_HOME}}}"
PILE_DOWN_ANDROID_SDK="${PILE_DOWN_ANDROID_SDK:-${ANDROID_HOME:-${ANDROID_SDK_ROOT:-${PILE_DOWN_DEFAULT_ANDROID_SDK}}}}"
if [[ "${PILE_DOWN_WINDOWS}" == true ]]; then
	if [[ -n "${PILE_DOWN_JAVA_HOME}" ]]; then
		PILE_DOWN_JAVA_HOME="$(cygpath -u "${PILE_DOWN_JAVA_HOME}")"
	fi
	PILE_DOWN_ANDROID_SDK="$(cygpath -u "${PILE_DOWN_ANDROID_SDK}")"
fi

PILE_DOWN_ANDROID_DIR="${PILE_DOWN_PLATFORMS_DIR}/android"
PILE_DOWN_ANDROID_OUTPUT="${PILE_DOWN_ANDROID_DIR}/pile-down-android-${PILE_DOWN_VERSION}.${PILE_DOWN_ANDROID_FORMAT}"
PILE_DOWN_ANDROID_EXPORT_MODE="${PILE_DOWN_ANDROID_EXPORT_MODE:-debug}"

if [[ -z "${PILE_DOWN_JAVA_HOME}" || ! -x "${PILE_DOWN_JAVA_HOME}/bin/java" || ! -x "${PILE_DOWN_JAVA_HOME}/bin/javac" ]]; then
	echo "Java JDK not found at: ${PILE_DOWN_JAVA_HOME:-<not configured>}" >&2
	echo "Install OpenJDK 17 and set JAVA_HOME or PILE_DOWN_JAVA_HOME to its installation directory." >&2
	exit 1
fi
PILE_DOWN_JAVAC_VERSION="$("${PILE_DOWN_JAVA_HOME}/bin/javac" -version 2>&1)"
if [[ ! "${PILE_DOWN_JAVAC_VERSION}" =~ javac[[:space:]]+([0-9]+) ]] || (( BASH_REMATCH[1] < 17 )); then
	echo "OpenJDK 17 or newer is required; found: ${PILE_DOWN_JAVAC_VERSION}" >&2
	exit 1
fi
if [[ "${PILE_DOWN_ANDROID_FORMAT}" == aab ]] && (( BASH_REMATCH[1] > 23 )); then
	echo "The Android AAB Gradle template requires JDK 17 to 23; found: ${PILE_DOWN_JAVAC_VERSION}" >&2
	echo "Set PILE_DOWN_JAVA_HOME to an OpenJDK 17 installation (recommended)." >&2
	exit 1
fi

if [[ ! -x "${PILE_DOWN_ANDROID_SDK}/platform-tools/adb" ]]; then
	echo "Android SDK not found at: ${PILE_DOWN_ANDROID_SDK}" >&2
	echo "Expected file: ${PILE_DOWN_ANDROID_SDK}/platform-tools/adb" >&2
	echo "You can override it with PILE_DOWN_ANDROID_SDK." >&2
	exit 1
fi

export PATH="${PILE_DOWN_JAVA_HOME}/bin:${PILE_DOWN_ANDROID_SDK}/platform-tools:${PATH}"
export JAVA_HOME="${PILE_DOWN_JAVA_HOME}"
export ANDROID_HOME="${PILE_DOWN_ANDROID_SDK}"
if [[ "${PILE_DOWN_WINDOWS}" == true ]]; then
	export JAVA_HOME="$(cygpath -m "${PILE_DOWN_JAVA_HOME}")"
	export ANDROID_HOME="$(cygpath -m "${PILE_DOWN_ANDROID_SDK}")"
fi
export ANDROID_SDK_ROOT="${ANDROID_HOME}"
# Gradle's Windows launcher echoes its command, including signing credentials,
# when an unrelated DEBUG environment variable is set.
unset DEBUG

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

			keytool \
				-keyalg RSA \
				-genkeypair \
				-alias androiddebugkey \
				-keypass android \
				-keystore "${PILE_DOWN_DEBUG_KEYSTORE}" \
				-storepass android \
				-dname "CN=Android Debug,O=Android,C=US" \
				-validity 9999 \
				-deststoretype PKCS12 \
				>/dev/null
		fi

		export GODOT_ANDROID_KEYSTORE_DEBUG_PATH="${PILE_DOWN_DEBUG_KEYSTORE}"
		if [[ "${PILE_DOWN_WINDOWS}" == true ]]; then
			export GODOT_ANDROID_KEYSTORE_DEBUG_PATH="$(cygpath -m "${PILE_DOWN_DEBUG_KEYSTORE}")"
		fi
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
XDG_CONFIG_HOME="${PILE_DOWN_CONFIG_HOME}" \
	"${PILE_DOWN_SCRIPT_DIR}/ensure_export_templates.sh" "${PILE_DOWN_TEMPLATE_PLATFORM}"

echo "Configuring Godot Android SDK and Java paths..."
"${PILE_DOWN_GODOT_BIN}" --headless --path . \
	--script res://resources/scripts/tools/ConfigureAndroidExport.gd

echo "Exporting Android ${PILE_DOWN_ANDROID_EXPORT_MODE} ${PILE_DOWN_ANDROID_FORMAT} to ${PILE_DOWN_ANDROID_OUTPUT}..."
XDG_DATA_HOME="${PILE_DOWN_DATA_HOME}" \
XDG_CONFIG_HOME="${PILE_DOWN_CONFIG_HOME}" \
	"${PILE_DOWN_GODOT_BIN}" \
	--headless \
	--path . \
	"${PILE_DOWN_ANDROID_FLAGS[@]}" \
	"${PILE_DOWN_EXPORT_FLAG}" \
	"${PILE_DOWN_ANDROID_PRESET}" \
	"${PILE_DOWN_ANDROID_OUTPUT}"

if [[ ! -s "${PILE_DOWN_ANDROID_OUTPUT}" ]]; then
	echo "Android export finished without producing an ${PILE_DOWN_ANDROID_FORMAT}: ${PILE_DOWN_ANDROID_OUTPUT}" >&2
	exit 1
fi

echo "Android ${PILE_DOWN_ANDROID_EXPORT_MODE} build ready: ${PILE_DOWN_ANDROID_OUTPUT}"
