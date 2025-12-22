#!/usr/bin/env bash

set -u

DEFAULT_LAYOUT=${DEFAULT_LAYOUT:-US}
MISSING_CMD_OUTPUT=${MISSING_CMD_OUTPUT:-ERR}

require_command() {
    local cmd=$1

    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "$MISSING_CMD_OUTPUT"
        return 1
    fi
}

read_layout() {
    xkblayout-state print %s 2>/dev/null | tr -d '[:space:]'
}

normalize_layout() {
    local layout=$1

    if [[ -z "$layout" ]]; then
        layout="$DEFAULT_LAYOUT"
    fi

    if [[ "$layout" == *"my_ru"* ]]; then
        echo "RU"
    else
        printf '%s\n' "${layout^^}"
    fi
}

main() {
    require_command xkblayout-state || return 1

    local current_layout
    current_layout=$(read_layout)

    normalize_layout "$current_layout"
}

main "$@"
