#!/usr/bin/env bash
set -euo pipefail

PILE_DOWN_PUBLISHING_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PILE_DOWN_PROJECT_DIR="$(cd -- "${PILE_DOWN_PUBLISHING_DIR}/.." && pwd)"
PILE_DOWN_SOURCE="${PILE_DOWN_PUBLISHING_DIR}/thumbnail.png"
PILE_DOWN_OUTPUT="${PILE_DOWN_PUBLISHING_DIR}/thumbnail-animated.gif"
PILE_DOWN_FRAME_DIR="$(mktemp -d)"
PILE_DOWN_TILE_COUNT=4
PILE_DOWN_START_STATE="empty"

trap 'rm -rf -- "${PILE_DOWN_FRAME_DIR}"' EXIT

show_help() {
	cat <<'EOF'
Usage: create_thumbnail_gif.sh [options]

Options:
  -n, --tiles COUNT       Number of tiles in the stack (1-10, default: 4).
      --start STATE       Initial stack state: "empty" or "full" (default: empty).
  -o, --output PATH       Output GIF path.
  -h, --help              Show this help.

Examples:
  ./publishing/create_thumbnail_gif.sh --tiles 7
  ./publishing/create_thumbnail_gif.sh --tiles 5 --start full
EOF
}

while (( $# > 0 )); do
	case "$1" in
		-n|--tiles)
			(( $# >= 2 )) || {
				echo "Missing value after $1." >&2
				exit 2
			}
			PILE_DOWN_TILE_COUNT="$2"
			shift 2
			;;
		--start)
			(( $# >= 2 )) || {
				echo "Missing value after $1." >&2
				exit 2
			}
			PILE_DOWN_START_STATE="$2"
			shift 2
			;;
		-o|--output)
			(( $# >= 2 )) || {
				echo "Missing value after $1." >&2
				exit 2
			}
			PILE_DOWN_OUTPUT="$2"
			shift 2
			;;
		-h|--help)
			show_help
			exit 0
			;;
		*)
			echo "Unknown option: $1" >&2
			show_help >&2
			exit 2
			;;
	esac
done

if [[ ! "${PILE_DOWN_TILE_COUNT}" =~ ^[0-9]+$ ]] ||
	(( PILE_DOWN_TILE_COUNT < 1 || PILE_DOWN_TILE_COUNT > 10 )); then
	echo "Tile count must be an integer between 1 and 10." >&2
	exit 2
fi

if [[ "${PILE_DOWN_START_STATE}" != "empty" && "${PILE_DOWN_START_STATE}" != "full" ]]; then
	echo "Start state must be either \"empty\" or \"full\"." >&2
	exit 2
fi

command -v magick >/dev/null || {
	echo "ImageMagick 7 is required to create the animated thumbnail." >&2
	exit 1
}

declare -a PILE_DOWN_LETTER_CROPS=(
	"18x58+67+89"
	"45x58+103+89"
	"29x58+158+89"
	"43x58+198+89"
	"39x58+252+89"
	"43x58+339+89"
	"45x58+387+89"
	"43x58+439+89"
	"43x58+486+89"
	"18x58+542+89"
)
declare -a PILE_DOWN_LETTER_X=(67 103 158 198 252 339 387 439 486 542)
declare -a PILE_DOWN_TILE_VALUES=()
declare -a PILE_DOWN_TILE_X=()
declare -a PILE_DOWN_TILE_Y=()

PILE_DOWN_TILE_STAGGER=4
# Keep every tile at the same animation speed and extend the loop for larger stacks.
PILE_DOWN_FRAME_COUNT=$((12 + 8 * (PILE_DOWN_TILE_COUNT - 1)))
PILE_DOWN_LAST_FRAME=$((PILE_DOWN_FRAME_COUNT - 1))
PILE_DOWN_VERTICAL_STEP=25
if (( PILE_DOWN_TILE_COUNT > 7 )); then
	PILE_DOWN_VERTICAL_STEP=$((155 / (PILE_DOWN_TILE_COUNT - 1)))
fi
PILE_DOWN_BOTTOM_X=$((247 + 9 * (PILE_DOWN_TILE_COUNT - 1)))

for ((PILE_DOWN_TILE_INDEX = 0; PILE_DOWN_TILE_INDEX < PILE_DOWN_TILE_COUNT; PILE_DOWN_TILE_INDEX++)); do
	PILE_DOWN_TILE_VALUES+=("$((PILE_DOWN_TILE_COUNT - 1 - PILE_DOWN_TILE_INDEX))")
	PILE_DOWN_TILE_X+=("$((PILE_DOWN_BOTTOM_X - 18 * PILE_DOWN_TILE_INDEX))")
	PILE_DOWN_TILE_Y+=("$((315 - PILE_DOWN_VERTICAL_STEP * PILE_DOWN_TILE_INDEX))")
done

for PILE_DOWN_VALUE in "${PILE_DOWN_TILE_VALUES[@]}"; do
	magick \
		"${PILE_DOWN_PROJECT_DIR}/build/renders/tiles/tile-${PILE_DOWN_VALUE}.png" \
		-filter point \
		-resize 400% \
		"${PILE_DOWN_FRAME_DIR}/tile-${PILE_DOWN_VALUE}.png"
done

for PILE_DOWN_FRAME in $(seq 0 "${PILE_DOWN_LAST_FRAME}"); do
	PILE_DOWN_FRAME_PATH="$(
		printf '%s/frame-%02d.png' "${PILE_DOWN_FRAME_DIR}" "${PILE_DOWN_FRAME}"
	)"
	magick -size 630x500 "xc:#f7f6f3" "${PILE_DOWN_FRAME_PATH}"

	for PILE_DOWN_LETTER_INDEX in "${!PILE_DOWN_LETTER_CROPS[@]}"; do
		PILE_DOWN_WAVE_Y="$(
			awk -v frame="${PILE_DOWN_FRAME}" -v letter_index="${PILE_DOWN_LETTER_INDEX}" \
				'BEGIN {
					pi = atan2(0, -1)
					printf "%d", 89 + 5 * sin(2 * pi * (frame / 18 + letter_index / 10))
				}'
		)"
		magick "${PILE_DOWN_FRAME_PATH}" \
			\( "${PILE_DOWN_SOURCE}" \
				-crop "${PILE_DOWN_LETTER_CROPS[PILE_DOWN_LETTER_INDEX]}" \
				+repage \) \
			-geometry "+${PILE_DOWN_LETTER_X[PILE_DOWN_LETTER_INDEX]}+${PILE_DOWN_WAVE_Y}" \
			-composite \
			"${PILE_DOWN_FRAME_PATH}"
	done

	for PILE_DOWN_TILE_INDEX in "${!PILE_DOWN_TILE_VALUES[@]}"; do
		if [[ "${PILE_DOWN_START_STATE}" == "empty" ]]; then
			PILE_DOWN_START=$((PILE_DOWN_TILE_STAGGER * PILE_DOWN_TILE_INDEX))
			PILE_DOWN_EXIT=$((PILE_DOWN_FRAME_COUNT - 6 - PILE_DOWN_TILE_STAGGER * PILE_DOWN_TILE_INDEX))
		else
			PILE_DOWN_EXIT=$((PILE_DOWN_TILE_STAGGER * (PILE_DOWN_TILE_COUNT - 1 - PILE_DOWN_TILE_INDEX)))
			PILE_DOWN_START=$((PILE_DOWN_FRAME_COUNT - 6 - PILE_DOWN_TILE_STAGGER * (PILE_DOWN_TILE_COUNT - 1 - PILE_DOWN_TILE_INDEX)))
		fi

		if [[ "${PILE_DOWN_START_STATE}" == "empty" ]] &&
			(( PILE_DOWN_FRAME < PILE_DOWN_START || PILE_DOWN_FRAME > PILE_DOWN_EXIT + 5 )); then
			continue
		fi
		if [[ "${PILE_DOWN_START_STATE}" == "full" ]] &&
			(( PILE_DOWN_FRAME > PILE_DOWN_EXIT + 5 && PILE_DOWN_FRAME < PILE_DOWN_START )); then
			continue
		fi

		if [[ "${PILE_DOWN_START_STATE}" == "full" ]] && (( PILE_DOWN_FRAME <= PILE_DOWN_EXIT + 5 )); then
			PILE_DOWN_TILE_CURRENT_Y="$(
				awk \
					-v frame="${PILE_DOWN_FRAME}" \
					-v start="${PILE_DOWN_EXIT}" \
					-v target="${PILE_DOWN_TILE_Y[PILE_DOWN_TILE_INDEX]}" \
					'BEGIN {
						if (frame < start) {
							printf "%d", target
							exit
						}
						t = (frame - start) / 5
						ease = t * t
						printf "%d", target + (510 - target) * ease
					}'
			)"
		elif (( PILE_DOWN_FRAME <= PILE_DOWN_START + 5 )); then
			PILE_DOWN_TILE_CURRENT_Y="$(
				awk \
					-v frame="${PILE_DOWN_FRAME}" \
					-v start="${PILE_DOWN_START}" \
					-v target="${PILE_DOWN_TILE_Y[PILE_DOWN_TILE_INDEX]}" \
					'BEGIN {
						t = (frame - start) / 5
						ease = 1 - (1 - t) ^ 3
						printf "%d", 510 + (target - 510) * ease
					}'
			)"
		elif [[ "${PILE_DOWN_START_STATE}" == "full" ]] || (( PILE_DOWN_FRAME < PILE_DOWN_EXIT )); then
			PILE_DOWN_TILE_CURRENT_Y="${PILE_DOWN_TILE_Y[PILE_DOWN_TILE_INDEX]}"
		else
			PILE_DOWN_TILE_CURRENT_Y="$(
				awk \
					-v frame="${PILE_DOWN_FRAME}" \
					-v start="${PILE_DOWN_EXIT}" \
					-v target="${PILE_DOWN_TILE_Y[PILE_DOWN_TILE_INDEX]}" \
					'BEGIN {
						t = (frame - start) / 5
						ease = t * t
						printf "%d", target + (510 - target) * ease
					}'
			)"
		fi
		magick "${PILE_DOWN_FRAME_PATH}" \
			"${PILE_DOWN_FRAME_DIR}/tile-${PILE_DOWN_TILE_VALUES[PILE_DOWN_TILE_INDEX]}.png" \
			-geometry "+${PILE_DOWN_TILE_X[PILE_DOWN_TILE_INDEX]}+${PILE_DOWN_TILE_CURRENT_Y}" \
			-composite \
			"${PILE_DOWN_FRAME_PATH}"
	done
done

magick \
	-delay 10 \
	"${PILE_DOWN_FRAME_DIR}"/frame-*.png \
	-loop 0 \
	-layers OptimizePlus \
	"${PILE_DOWN_OUTPUT}"

echo "Animated thumbnail ready: ${PILE_DOWN_OUTPUT}"
