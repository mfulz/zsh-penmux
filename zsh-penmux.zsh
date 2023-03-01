#!/usr/bin/env zsh
#
# Includes
#
CURRENT_DIR=$(exec 2>/dev/null;cd -- $(dirname "$0"); unset PWD; /usr/bin/pwd || /bin/pwd || pwd)
source "${CURRENT_DIR}/zsh-penmux-defines.zsh"

#
# Aliases
#
alias pmSS='penmux_start_session'
alias pmES='penmux_end_session'
alias pmNT='penmux_new_task'
alias pmNA='penmux_new_action'

#
# Functions
#
penmux_start_session() {
    local SESSION_NAME="$(date +"%Y%m%dT%H%M")"
    local TASK_NAME="ENUMERATION"
    local ACTION_NAME="SCAN"
    local WORK_DIR="$(pwd)"
    local SESSION_EXISTS="$(_get_existing_session "${SESSION_NAME}")"

    local OPTIND o
    while getopts "s:t:a:lh" o; do
        case "${o}" in
            s)
                SESSION_NAME="${OPTARG}"
                ;;
            t)
                TASK_NAME="${OPTARG}"
                ;;
            a)
                ACTION_NAME="${OPTARG}"
                ;;
            d)
                WORK_DIR="$(_absolute_path "${OPTARG}")"
                ;;
            h)
                echo "TODO: Help" && return 0
                ;;
            *)
                echo "TODO: Help" && return 1
                ;;
        esac
    done

    if [[ "${SESSION_EXISTS}" != "" ]]; then
        _if_tmux && { >&2 echo "Tmux already running"; return 1 }
        tmux attach-session -t "${SESSION_NAME}"
    else
        tmux new-session -Ac "${WORK_DIR}" -s "${SESSION_NAME}" \; \
            set-option -q "@la-work-dir" "${WORK_DIR}" \; \
            set-environment PENMUX_SESSION "${SESSION_NAME}" \; \
            rename-window "${TASK_NAME}" \; \
            select-pane -T "${ACTION_NAME}"
    fi
}

penmux_end_session() {
    _if_tmux || { >&2 echo "No tmux session"; return 1 }
    _if_penmux_session || { >&2 echo "No penmux session"; return 1 }
    local SESSION_NAME="$(_get_session_name)"

    # stop logging if running on all panes
    for _window in $(tmux list-windows -a -f "#{==:#{session_name},"${SESSION_NAME}"}" -F "#I"); do
        tmux select-window -t "${_window}"
        for _pane in $(tmux list-panes -F "#D"); do
            tmux select-pane -t "${_pane}"
            tmux run -t "${_pane}" "${TMUX_LOGGING_EXTENDED_TOGGLE_LOG} stop"
        done
    done
    
    # give script stop some time
    for _pane in $(tmux list-panes -a -f "#{==:#{session_name},"${SESSION_NAME}"}" -F "#D"); do
        tmux kill-pane -t "${_pane}"
    done

    # check if something is still left and kill
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
