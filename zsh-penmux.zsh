#!/usr/bin/env zsh
#
# Includes
#
CURRENT_DIR=$(exec 2>/dev/null;cd -- $(dirname "$0"); unset PWD; /usr/bin/pwd || /bin/pwd || pwd)
source "${CURRENT_DIR}/zsh-penmux-defines.zsh"
source "${CURRENT_DIR}/zsh-penmux-shared.zsh"

#
# Aliases
#
alias pmCS='penmux_create_session'
alias pmAS='penmux_attach_session'
alias pmES='penmux_end_session'
alias pmNT='penmux_new_task'
alias pmNA='penmux_new_action'
alias pmTA='penmux_toggle_log_action'
alias pmAA='penmux_add_log_action'
alias pmDA='penmux_del_log_action'
alias pmGA='penmux_get_log_action'
alias pmTL='penmux_toggle_log'
alias pmSL='penmux_start_log'
alias pmEL='penmux_stop_log'

#
# Functions
#
penmux_create_session() {
    local SESSION_NAME="$(date +"%Y%m%dT%H%M")"
    local TASK_NAME="ENUMERATION"
    local ACTION_NAME="SCAN"
    local WORK_DIR="$(pwd)"
    local LOG=1
    local SESSION_EXISTS="$(_get_existing_session "${SESSION_NAME}")"

    local OPTIND o
    while getopts "s:t:a:lnh" o; do
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
            n)
                LOG=0
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
        >&2 echo "Session already exists"; return 1 }
    else
        tmux new-session -dc "${WORK_DIR}" -s "${SESSION_NAME}" \; \
            set-option -q "@la-work-dir" "${WORK_DIR}" \; \
            set-environment PENMUX_SESSION "${SESSION_NAME}" \; \
            set-environment PENMUX_LOG_ACTIONS "" \; \
            rename-window "${TASK_NAME}" \; \
            select-pane -T "${ACTION_NAME}"

        if [[ "${LOG}" -ne 0 ]]; then
            local LOG_ACTIONS=""
            local _pane="$(tmux list-panes -a -f "#{==:#{session_name},"${SESSION_NAME}"}" -F "#D")"

            tmux run -t "${_pane}" -C "set-environment PENMUX_LOG_ACTIONS "${_pane}""
        fi
    fi
}

penmux_attach_session() {
    local SESSION_NAME="$(date +"%Y%m%dT%H%M")"
    local SESSION_EXISTS="$(_get_existing_session "${SESSION_NAME}")"

    local OPTIND o
    while getopts "s:t:a:lnh" o; do
        case "${o}" in
            s)
                SESSION_NAME="${OPTARG}"
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
        _if_tmux && { >&2 echo "Tmux detected. Please exit first."; return 1 }
        tmux attach-session -t "${SESSION_NAME}"
    else
        >&2 echo "Session not found: '${SESSION_NAME}'" && return 1
    fi
}

penmux_end_session() {
    _if_tmux || { >&2 echo "No tmux session"; return 1 }
    _if_penmux_session || { >&2 echo "No penmux session"; return 1 }
    local SESSION_NAME="$(_get_session_name)"

    # stop logging if running on all panes
    for _pane in $(tmux list-panes -a -f "#{==:#{session_name},"${SESSION_NAME}"}" -F "#D"); do
        #tmux select-pane -t "${_pane}"
        tmux run -t "${_pane}" "${TMUX_LOGGING_EXTENDED_TOGGLE_LOG} -a stop -p "${_pane}""
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

penmux_toggle_log_action() {
    local PANE_ID="$(_get_action_id)"

    _in_tmux_env_list PENMUX_LOG_ACTIONS "${PANE_ID}" && _del_tmux_env_list PENMUX_LOG_ACTIONS "${PANE_ID}" || _add_tmux_env_list PENMUX_LOG_ACTIONS "${PANE_ID}"
}

penmux_add_log_action() {
    local PANE_ID="$(_get_action_id)"

    _add_tmux_env_list PENMUX_LOG_ACTIONS "${PANE_ID}"
}

penmux_del_log_action() {
    local PANE_ID="$(_get_action_id)"

    _del_tmux_env_list PENMUX_LOG_ACTIONS "${PANE_ID}"
}

penmux_get_log_action() {
    local PANE_ID="$(_get_action_id)"

    _in_tmux_env_list PENMUX_LOG_ACTIONS "${PANE_ID}" && tmux display-message -d 5000 "penmux logging enabled" || tmux display-message -d 5000 "penmux logging disabled"
}

penmux_toggle_log() {
    for _pane in $(_get_tmux_env_list PENMUX_LOG_ACTIONS); do
        tmux run -t "${_pane}" "${TMUX_LOGGING_EXTENDED_TOGGLE_LOG} -p "${_pane}""
    done
}

penmux_start_log() {
    for _pane in $(_get_tmux_env_list PENMUX_LOG_ACTIONS); do
        tmux run -t "${_pane}" "${TMUX_LOGGING_EXTENDED_TOGGLE_LOG} -a start -p "${_pane}""
    done
}

penmux_stop_log() {
    for _pane in $(_get_tmux_env_list PENMUX_LOG_ACTIONS); do
        tmux run -t "${_pane}" "${TMUX_LOGGING_EXTENDED_TOGGLE_LOG} -a stop -p "${_pane}""
    done
}
