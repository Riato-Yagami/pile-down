#!/usr/bin/env bash

set -euo pipefail

PILE_DOWN_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${PILE_DOWN_SCRIPT_DIR}/../.." && pwd)"

# Charge les variables locales du projet
if [[ -f "${PROJECT_ROOT}/.env" ]]; then
    set -a
    source "${PROJECT_ROOT}/.env"
    set +a
fi

exec bash "${PILE_DOWN_SCRIPT_DIR}/build_android.sh" --aab "$@"