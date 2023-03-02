#!/usr/bin/env zsh
#
# Helper Functions
#
_absolute_path() {
    echo "$(cd "$(dirname -- "$1")" >/dev/null; pwd -P)/$(basename -- "$1")"
}

_if_tmux() {
    (( ${+TMUX} )) || return 1
}

_if_penmux_session() {
    _if_tmux || return 1
    tmux show-environment PENMUX_SESSION >/dev/null 2>&1 || return 1
}

_get_action_id() {
    # dont use directly
    tmux display-message -p "#{pane_id}"
}

_get_task_name() {
    # dont use directly
    tmux display-message -p "#{window_name}"
}

_get_task_id() {
    tmux display-message -p "#{window_id}"
}

_get_session_name_by_pid() {
    local PANE_ID="${1}"

    echo "$(tmux list-panes -aF "#S" -f "#{==:#D,"${PANE_ID}"}")"
}

_get_task_id_by_name() {
    local SESSION_NAME="${1}"
    local TASK_NAME="${2}"

    echo "$(tmux list-windows -aF "#{window_id}" -f "#{==:#S#W,${SESSION_NAME}${TASK_NAME}}")"
}

_get_task_name_by_id() {
    local TASK_ID="${1}"

    echo "$(tmux list-windows -aF "#W" -f "#{==:#{window_id},${TASK_ID}}")"
}

_get_session_name() {
    # dont use directly
    tmux display-message -p "#{session_name}"
}

_get_existing_session() {
    local SESSION_NAME="${1}"
    tmux list-sessions -f "#{==:#{session_name},${SESSION_NAME}}" -F\#S
}

_if_tmux_env_var() {
    local SESSION_NAME="${1}"
    local ENV_NAME="${2}"
    tmux show-environment -t "${SESSION_NAME}" "${ENV_NAME}" >/dev/null 2>&1 || return 1
}

_get_tmux_env_val() {
    local SESSION_NAME="${1}"
    local ENV_NAME="${2}"
    local ENV_VAR=""

    tmux show-environment -t "${SESSION_NAME}" "${ENV_NAME}" >/dev/null || return 1
    ENV_VAR="$(tmux show-environment -t "${SESSION_NAME}" "${ENV_NAME}")"

    ENV_VAL=("${(@s/=/)ENV_VAR}")
    echo ${ENV_VAL[2]}
}

_get_tmux_env_list() {
    local SESSION_NAME="${1}"
    local ENV_VAR="${2}"
    local ENV_VAL=""

    _if_tmux_env_var "${SESSION_NAME}" "${ENV_VAR}" || tmux set-environment -t "${SESSION_NAME}" "${ENV_VAR}"
    ENV_VAL=$(_get_tmux_env_val "${SESSION_NAME}" "${ENV_VAR}")

    LIST_VAL=("${(@s/#/)ENV_VAL}")
    echo ${LIST_VAL}
}

_add_tmux_env_list() {
    local SESSION_NAME="${1}"
    local ENV_VAR="${2}"
    local ENV_ENTRY="${3}"
    local ENV_VAL=""

    _in_tmux_env_list "${SESSION_NAME}" "${ENV_VAR}" "${ENV_ENTRY}" && return 0

    ENV_VAL="$(_get_tmux_env_val "${SESSION_NAME}" "${ENV_VAR}")#${ENV_ENTRY}"
    tmux set-environment -t "${SESSION_NAME}" "${ENV_VAR}" "${ENV_VAL}"
}

_del_tmux_env_list() {
    local SESSION_NAME="${1}"
    local ENV_VAR="${2}"
    local ENV_ENTRY="${3}"
    local ENV_VAL=""

    _in_tmux_env_list "${SESSION_NAME}" "${ENV_VAR}" "${ENV_ENTRY}" || return 0

    for e in $(_get_tmux_env_list "${SESSION_NAME}" "${ENV_VAR}"); do
        if [[ "${e}" != "${ENV_ENTRY}" ]]; then
            if [[ "${ENV_VAL}" == "" ]]; then
                ENV_VAL="${e}"
            else
                ENV_VAL="${ENV_VAL}#${e}"
            fi
        fi
    done

    tmux set-environment -t "${SESSION_NAME}" "${ENV_VAR}" "${ENV_VAL}"
}

_in_tmux_env_list() {
    local SESSION_NAME="${1}"
    local ENV_VAR="${2}"
    local ENV_ENTRY="${3}"

    local ENTRY_EXISTS=1
    for e in $(_get_tmux_env_list "${SESSION_NAME}" "${ENV_VAR}"); do
        if [[ "${e}" == "${ENV_ENTRY}" ]]; then
            ENTRY_EXISTS=0
            break
        fi
    done

    return ${ENTRY_EXISTS}
}

_if_action_duplicate_by_id() {
    local PANE_ID="${1}"
    local ACTION_NAME="${2}"

    local _swt="$(tmux list-panes -aF "#S #W" -f "#{==:#{pane_id},${PANE_ID}}")"

    _if_action_duplicate ${=_swt} "${ACTION_NAME}"
}

_if_action_duplicate() {
    local SESSION_NAME="${1}"
    local TASK_NAME="${2}"
    local ACTION_NAME="${3}"

    local _pane="$(tmux list-panes -aF "#T" -f "#{==:#S#W#T,${SESSION_NAME}${TASK_NAME}${ACTION_NAME}}")"

    if [[ "${_pane}" == "" ]]; then
        return 0
    fi
    return 1
}

_if_task_name_unique() {
    local SESSION_NAME="${1}"
    local TASK_NAME="${2}"

    local _count=$(tmux list-windows -af "#{==:#S#W,${SESSION_NAME}${TASK_NAME}}" | wc -l)

    if [[ "${_count}" -eq 1 ]]; then
        return 0
    fi
    return 1
}

_if_valid_session() {
    local SESSION_NAME="${1}"
    local _check="$(tmux show-environment -t "${SESSION_NAME}" PENMUX_SESSION 2>/dev/null)"

    if [[ "${_check}" == "PENMUX_SESSION=${SESSION_NAME}" ]]; then
        return 0
    fi
    return 1
}
