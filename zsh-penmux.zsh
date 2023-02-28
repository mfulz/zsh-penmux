#!/usr/bin/env zsh
#
# Includes
#
CURRENT_DIR=$(exec 2>/dev/null;cd -- $(dirname "$0"); unset PWD; /usr/bin/pwd || /bin/pwd || pwd)
source "${CURRENT_DIR}/zsh-penmux-defines.zsh"

#
# Aliases
#
alias pmuSS='penmux_start_session'
alias pmuES='penmux_end_session'

#
# Functions
#
penmux_start_session() {
    local SESSION_NAME="${1}"
    local WORK_DIR="$(pwd)"
    local TASK_NAME="ENUMERATION"
    local ACTION_NAME="SCAN"
    local SESSION_EXISTS="$(_get_existing_session "${SESSION_NAME}")"

    if (( ${+2} )); then
        WORK_DIR="$(_absolute_path "${2}")"
    fi

    if (( ${+3} )); then
        TASK_NAME="${3}"
    fi

    if (( ${+4} )); then
        ACTION_NAME="${4}"
    fi

    if [[ "${SESSION_EXISTS}" != "" ]]; then
        tmux attach-session -t "${SESSION_NAME}"
    else
        tmux new-session -Ac "${WORK_DIR}" -s "${SESSION_NAME}" \; \
            set-option -q "@la-work-dir" "${WORK_DIR}" \; \
            set-environment PENMUX_SESSION "${SESSION_NAME}" \; \
            rename-window "${TASK_NAME}" \; \
            select-pane -T "${ACTION_NAME}" \; \
            run ${TMUX_LOGGING_EXTENDED_TOGGLE_LOG}
    fi
}

penmux_end_session() {
    _if_tmux || { >&2 echo "No tmux session"; return 1 }
    _if_penmux_session || { >&2 echo "No penmux session"; return 1 }

    tmux kill-session -t "$(_get_session_name)"
}

penmux_set_task() {
    _if_tmux || { >&2 echo "No tmux session"; return 1 }
    _if_penmux_session || { >&2 echo "No penmux session"; return 1 }
    local TASK_NAME="${1}"

    tmux rename-window "${TASK_NAME}"
}

penmux_new_task() {
    _if_tmux || { >&2 echo "No tmux session"; return 1 }
    _if_penmux_session || { >&2 echo "No penmux session"; return 1 }
    local TASK_NAME="${1}"

    tmux new-window -n "${TASK_NAME}"
}

penmux_set_action() {
    _if_tmux || { >&2 echo "No tmux session"; return 1 }
    _if_penmux_session || { >&2 echo "No penmux session"; return 1 }
    local ACTION_NAME="${1}"

    tmux select-pane -T "${ACTION_NAME}"
}

penmux_new_action() {
    local ACTION_NAME="${1}"
    local TASK_NAME="$(_get_task_name)"

    penmux_new_task "${TASK_NAME}"
    penmux_set_action "${ACTION_NAME}"
}

#
# Helper functions
#
_absolute_path() {
    echo "$(cd "$(dirname -- "$1")" >/dev/null; pwd -P)/$(basename -- "$1")"
}

_if_tmux() {
    (( ${+TMUX} )) || return 1
}

_if_penmux_session() {
    tmux show-environment PENMUX_SESSION >/dev/null 2>&1 || return 1
}

_get_task_name() {
    # dont use directly
    tmux display-message -p "#{window_name}"
}

_get_session_name() {
    # dont use directly
    tmux display-message -p "#{session_name}"
}

_get_existing_session() {
    local SESSION_NAME="${1}"
    tmux list-sessions -f "#{==:#{session_name},${SESSION_NAME}}" -F\#S
}
