#!/usr/bin/env zsh
#
# Includes
#
CURRENT_DIR=$(exec 2>/dev/null;cd -- $(dirname "$0"); unset PWD; /usr/bin/pwd || /bin/pwd || pwd)
source "${CURRENT_DIR}/zsh-penmux-defines.zsh"
source "${CURRENT_DIR}/zsh-penmux-shared.zsh"
source "${CURRENT_DIR}/zsh-penmux-layout.zsh"

if [[ -e "${CUSTOM_USER_FILE}" ]]; then
    source "${CUSTOM_USER_FILE}"
fi

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
    local SESSION_EXISTS="$(_get_existing_session "${SESSION_NAME}")"
    
    if [[ "${SESSION_EXISTS}" != "" ]]; then
        { >&2 echo "Session already exists"; return 1 }
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

penmux_start_layout_session() {
    local SESSION_NAME=""
    local LAYOUT_NAME=""

    local OPTIND o
    while getopts "s:l:" o; do
        case "${o}" in
            s)
                SESSION_NAME="${OPTARG}"
                ;;
            l)
                LAYOUT_NAME="${OPTARG}"
                ;;
            h)
                echo "TODO: Help" && return 0
                ;;
            *)
                echo "TODO: Help" && return 1
                ;;
        esac
    done

    local _layout_file="${CUSTOM_LAYOUTS}/${LAYOUT_NAME}.json"
    if [[ ! -e "${_layout_file}" ]]; then
        _layout_file="${PENMUX_LAYOUTS}/${LAYOUT_NAME}.json"
    fi
    if [[ ! -e "${_layout_file}" ]]; then
        { >&2 echo "Layout not found"; return 1 }
    fi

    if [[ "${SESSION_NAME}" == "" ]]; then
        { >&2 echo "Missing session name"; return 1 }
    fi

    local _sec_cmds=$(_layout_parse_tasks "${SESSION_NAME}" "${_layout_file}")
    while IFS= read -r c; do
        eval "${c} || return 1"
    done < <(printf '%s\n' "${_sec_cmds}")

    penmux_start_log "${SESSION_NAME}"
    penmux_attach_session -s "${SESSION_NAME}"
}

penmux_attach_session() {
    local SESSION_NAME="$(date +"%Y%m%dT%H%M")"

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

    _if_valid_session "${SESSION_NAME}" || { >&2 echo "Invalid session '${SESSION_NAME}'"; return 1 }
    _if_tmux && { >&2 echo "Tmux detected. Please exit first."; return 1 }

    tmux attach-session -t "${SESSION_NAME}"
}

penmux_end_session() {
    local SESSION_NAME="$(_get_session_name)"

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

    _if_valid_session "${SESSION_NAME}" || { >&2 echo "Invalid session '${SESSION_NAME}'"; return 1 }
    local pane_self=""
    _if_tmux && { _pane_self="$(_get_action_id)" }
    
    # stop logging if running on all panes
    for _pane in $(tmux list-panes -a -f "#{==:#{session_name},"${SESSION_NAME}"}" -F "#D"); do
        #tmux select-pane -t "${_pane}"
        tmux run -t "${_pane}" "${TMUX_LOGGING_EXTENDED_TOGGLE_LOG} -a stop -p "${_pane}""
    done

    # give script stop some time
    for _pane in $(tmux list-panes -a -f "#{==:#{session_name},"${SESSION_NAME}"}" -F "#D"); do
        if [[ "${_pane}" != "${_pane_self}" ]]; then
            tmux kill-pane -t "${_pane}"
        fi
    done
    if [[ "${_pane_self}" != "" ]]; then
        tmux kill-pane -t "${_pane}"
    fi

    # check if something is still left and kill
    _if_valid_session "${SESSION_NAME}" || return 0
    tmux kill-session -t "${SESSION_NAME}"
}

penmux_rename_task() {
    local SESSION_NAME=""
    local TASK_NAME=""
    local TASK_ID=""
    local NEW_TASK_NAME=""

    local OPTIND o
    while getopts "s:t:i:n:" o; do
        case "${o}" in
            s)
                SESSION_NAME="${OPTARG}"
                ;;
            t)
                TASK_NAME="${OPTARG}"
                ;;
            i)
                TASK_ID="${OPTARG}"
                ;;
            n)
                NEW_TASK_NAME="${OPTARG}"
                ;;
            *)
                echo "TODO: Help" && return 1
                ;;
        esac
    done

    if [[ "${NEW_TASK_NAME}" == "" ]]; then
        { >&2 echo "New task name required"; return 1 }
    fi

    if [[ "${SESSION_NAME}" == "" ]]; then
        _if_penmux_session || { >&2 echo "No penmux session"; return 1 }
        SESSION_NAME="$(_get_session_name)"
    fi

    if [[ "${TASK_NAME}" != "" && "${TASK_ID}" != "" ]]; then
        { >&2 echo "Specify either TASK_NAME or TASK_ID not both"; return 1 }
    elif [[ "${TASK_NAME}" != "" ]]; then
        _if_task_name_unique "${SESSION_NAME}" "${TASK_NAME}" || { >&2 echo "Task '${TASK_NAME}' not unique or not existing. Please specify TASK_ID."; return 1 }
        TASK_ID="$(_get_task_id_by_name "${SESSION_NAME}" "${TASK_NAME}")"
    elif [[ "${TASK_ID}" != "" ]]; then
        TASK_NAME="$(_get_task_name_by_id "${TASK_ID}")"
        _if_task_name_unique "${SESSION_NAME}" "${TASK_NAME}" || { >&2 echo "Task ID '${TASK_ID}' invalid."; return 1 }
    else
        _if_penmux_session || { >&2 echo "No penmux session"; return 1 }
        TASK_NAME="$(_get_task_name)"
        TASK_ID="$(_get_task_id)"
    fi

    _if_valid_session "${SESSION_NAME}" || { >&2 echo "Invalid session '${SESSION_NAME}'"; return 1 }
    _if_action_duplicate_by_task "${SESSION_NAME}" "${NEW_TASK_NAME}" || { >&2 echo "Conflicting Action name"; return 1 }

    tmux rename-window -t "${TASK_ID}" "${NEW_TASK_NAME}"
}

penmux_new_task() {
    local SESSION_NAME=""
    local TASK_NAME=""
    local ACTION_NAME=""
    local LOG=1
    local TMUX_FLAGS=""

    local OPTIND o
    while getopts "s:t:a:nd" o; do
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
            n)
                LOG=0
                ;;
            d)
                TMUX_FLAGS="${TMUX_FLAGS} -d"
                ;;
            *)
                echo "TODO: Help" && return 1
                ;;
        esac
    done

    if [[ "${TASK_NAME}" == "" ]]; then
        { >&2 echo "Task name required"; return 1 }
    fi

    if [[ "${ACTION_NAME}" == "" ]]; then
        { >&2 echo "Action name required"; return 1 }
    fi

    if [[ "${SESSION_NAME}" == "" ]]; then
        _if_penmux_session || { >&2 echo "No penmux session"; return 1 }
        SESSION_NAME="$(_get_session_name)"
    fi

    _if_valid_session "${SESSION_NAME}" || { >&2 echo "Invalid session '${SESSION_NAME}'"; return 1 }
    _if_action_duplicate "${SESSION_NAME}" "${TASK_NAME}" "${ACTION_NAME}" || { >&2 echo "Action already existing"; return 1 }
    local _pane="$(tmux new-window ${=TMUX_FLAGS} -t "${SESSION_NAME}" -n "${TASK_NAME}" -F "#D" -P)"

    tmux select-pane -t "${_pane}" -T "${ACTION_NAME}"

    if [[ "${LOG}" -ne 0 ]]; then
        _add_tmux_env_list "${SESSION_NAME}" PENMUX_LOG_ACTIONS "${_pane}"
    fi
}

penmux_rename_action() {
    local ACTION_NAME="${1}"
    local SESSION_NAME="$(_get_session_name)"
    local PANE_ID="$(_get_action_id)"

    if [[ "${2}" != "" ]]; then
        PANE_ID="${2}"
        SESSION_NAME="$(_get_session_name_by_pid "${PANE_ID}")"
    fi

    if [[ "${SESSION_NAME}" == "" ]]; then
        { >&2 echo "Invalid pand id. Session not found"; return 1 }
    fi

    _if_valid_session "${SESSION_NAME}" || { >&2 echo "Invalid session '${SESSION_NAME}'"; return 1 }
    _if_action_duplicate_by_id "${PANE_ID}" "${ACTION_NAME}" || { >&2 echo "Action already exiting"; return 1 }
    tmux select-pane -t "${PANE_ID}" -T "${ACTION_NAME}"
}

penmux_new_action() {
    local SESSION_NAME=""
    local TASK_NAME=""
    local TASK_ID=""
    local ACTION_NAME=""
    local LOG=1
    local TMUX_FLAGS=""

    local OPTIND o
    while getopts "s:t:i:a:nbdhvf" o; do
        case "${o}" in
            s)
                SESSION_NAME="${OPTARG}"
                ;;
            t)
                TASK_NAME="${OPTARG}"
                ;;
            i)
                TASK_ID="${OPTARG}"
                ;;
            a)
                ACTION_NAME="${OPTARG}"
                ;;
            n)
                LOG=0
                ;;
            b)
                TMUX_FLAGS="${TMUX_FLAGS} -b"
                ;;
            d)
                TMUX_FLAGS="${TMUX_FLAGS} -d"
                ;;
            h)
                TMUX_FLAGS="${TMUX_FLAGS} -h"
                ;;
            v)
                TMUX_FLAGS="${TMUX_FLAGS} -v"
                ;;
            f)
                TMUX_FLAGS="${TMUX_FLAGS} -f"
                ;;
            *)
                echo "TODO: Help" && return 1
                ;;
        esac
    done

    if [[ "${ACTION_NAME}" == "" ]]; then
        { >&2 echo "Action name required"; return 1 }
    fi

    if [[ "${SESSION_NAME}" == "" ]]; then
        _if_penmux_session || { >&2 echo "No penmux session"; return 1 }
        SESSION_NAME="$(_get_session_name)"
    fi

    if [[ "${TASK_NAME}" != "" && "${TASK_ID}" != "" ]]; then
        { >&2 echo "Specify either TASK_NAME or TASK_ID not both"; return 1 }
    elif [[ "${TASK_NAME}" != "" ]]; then
        _if_task_name_unique "${SESSION_NAME}" "${TASK_NAME}" || { >&2 echo "Task '${TASK_NAME}' not unique or not existing. Please specify TASK_ID."; return 1 }
        TASK_ID="$(_get_task_id_by_name "${SESSION_NAME}" "${TASK_NAME}")"
    elif [[ "${TASK_ID}" != "" ]]; then
        TASK_NAME="$(_get_task_name_by_id "${TASK_ID}")"
        _if_task_name_unique "${SESSION_NAME}" "${TASK_NAME}" || { >&2 echo "Task ID '${TASK_ID}' invalid."; return 1 }
    else
        _if_penmux_session || { >&2 echo "No penmux session"; return 1 }
        TASK_NAME="$(_get_task_name)"
        TASK_ID="$(_get_task_id)"
    fi

    _if_valid_session "${SESSION_NAME}" || { >&2 echo "Invalid session '${SESSION_NAME}'"; return 1 }
    _if_action_duplicate "${SESSION_NAME}" "${TASK_NAME}" "${ACTION_NAME}" || { >&2 echo "Action already exiting"; return 1 }
    _pane="$(tmux split-window ${=TMUX_FLAGS} -t "${TASK_ID}" -P -F "#D")"
    tmux select-pane -t "${_pane}" -T "${ACTION_NAME}"

    if [[ "${LOG}" -ne 0 ]]; then
        _add_tmux_env_list "${SESSION_NAME}" PENMUX_LOG_ACTIONS "${_pane}"
    fi
}

penmux_toggle_log_action() {
    local SESSION_NAME="$(_get_session_name)"
    local PANE_ID="$(_get_action_id)"

    if [[ "${1}" != "" ]]; then
        PANE_ID="${1}"
        SESSION_NAME="$(_get_session_name_by_pid "${PANE_ID}")"
    fi

    if [[ "${SESSION_NAME}" == "" ]]; then
        { >&2 echo "Invalid pand id. Session not found"; return 1 }
    fi

    _if_valid_session "${SESSION_NAME}" || { >&2 echo "Invalid session '${SESSION_NAME}'"; return 1 }
    _in_tmux_env_list "${SESSION_NAME}" PENMUX_LOG_ACTIONS "${PANE_ID}" && _del_tmux_env_list "${SESSION_NAME}" PENMUX_LOG_ACTIONS "${PANE_ID}" || _add_tmux_env_list "${SESSION_NAME}" PENMUX_LOG_ACTIONS "${PANE_ID}"
}

penmux_add_log_action() {
    local SESSION_NAME="$(_get_session_name)"
    local PANE_ID="$(_get_action_id)"

    if [[ "${1}" != "" ]]; then
        PANE_ID="${1}"
        SESSION_NAME="$(_get_session_name_by_pid "${PANE_ID}")"
    fi

    if [[ "${SESSION_NAME}" == "" ]]; then
        { >&2 echo "Invalid pand id. Session not found"; return 1 }
    fi

    _if_valid_session "${SESSION_NAME}" || { >&2 echo "Invalid session '${SESSION_NAME}'"; return 1 }
    _add_tmux_env_list "${SESSION_NAME}" PENMUX_LOG_ACTIONS "${PANE_ID}"
}

penmux_del_log_action() {
    local SESSION_NAME="$(_get_session_name)"
    local PANE_ID="$(_get_action_id)"

    if [[ "${1}" != "" ]]; then
        PANE_ID="${1}"
        SESSION_NAME="$(_get_session_name_by_pid "${PANE_ID}")"
    fi

    if [[ "${SESSION_NAME}" == "" ]]; then
        { >&2 echo "Invalid pand id. Session not found"; return 1 }
    fi

    _if_valid_session "${SESSION_NAME}" || { >&2 echo "Invalid session '${SESSION_NAME}'"; return 1 }
    _del_tmux_env_list "${SESSION_NAME}" PENMUX_LOG_ACTIONS "${PANE_ID}"
}

penmux_get_log_action() {
    local SESSION_NAME="$(_get_session_name)"
    local PANE_ID="$(_get_action_id)"
    local STD_OUT=0

    if [[ "${1}" != "" ]]; then
        PANE_ID="${1}"
        SESSION_NAME="$(_get_session_name_by_pid "${PANE_ID}")"
        STD_OUT=1
    fi

    if [[ "${SESSION_NAME}" == "" ]]; then
        { >&2 echo "Invalid pand id. Session not found"; return 1 }
    fi

    _if_valid_session "${SESSION_NAME}" || { >&2 echo "Invalid session '${SESSION_NAME}'"; return 1 }
    if [[ "${STD_OUT}" -eq 0 ]]; then
        _in_tmux_env_list "${SESSION_NAME}" PENMUX_LOG_ACTIONS "${PANE_ID}" && tmux display-message -t "${SESSION_NAME}" -d 5000 "penmux logging enabled" || tmux display-message -t "${SESSION_NAME}" -d 5000 "penmux logging disabled"
    else
        _in_tmux_env_list "${SESSION_NAME}" PENMUX_LOG_ACTIONS "${PANE_ID}" && echo "penmux logging enabled" || echo "penmux logging disabled"
    fi
}

penmux_toggle_log() {
    local SESSION_NAME="$(_get_session_name)"

    if [[ "${1}" != "" ]]; then
        SESSION_NAME="${1}"
    fi

    _if_valid_session "${SESSION_NAME}" || { >&2 echo "Invalid session '${SESSION_NAME}'"; return 1 }
    for _pane in $(_get_tmux_env_list "${SESSION_NAME}" PENMUX_LOG_ACTIONS); do
        tmux run -t "${_pane}" "${TMUX_LOGGING_EXTENDED_TOGGLE_LOG} -p "${_pane}""
    done
}

penmux_start_log() {
    local SESSION_NAME="$(_get_session_name)"

    if [[ "${1}" != "" ]]; then
        SESSION_NAME="${1}"
    fi

    _if_valid_session "${SESSION_NAME}" || { >&2 echo "Invalid session '${SESSION_NAME}'"; return 1 }
    for _pane in $(_get_tmux_env_list "${SESSION_NAME}" PENMUX_LOG_ACTIONS); do
        tmux run -t "${_pane}" "${TMUX_LOGGING_EXTENDED_TOGGLE_LOG} -a start -p "${_pane}""
    done
}

penmux_stop_log() {
    local SESSION_NAME="$(_get_session_name)"

    if [[ "${1}" != "" ]]; then
        SESSION_NAME="${1}"
    fi

    _if_valid_session "${SESSION_NAME}" || { >&2 echo "Invalid session '${SESSION_NAME}'"; return 1 }
    for _pane in $(_get_tmux_env_list "${SESSION_NAME}" PENMUX_LOG_ACTIONS); do
        tmux run -t "${_pane}" "${TMUX_LOGGING_EXTENDED_TOGGLE_LOG} -a stop -p "${_pane}""
    done
}
