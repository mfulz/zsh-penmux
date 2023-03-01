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

_get_session_name() {
    # dont use directly
    tmux display-message -p "#{session_name}"
}

_get_existing_session() {
    local SESSION_NAME="${1}"
    tmux list-sessions -f "#{==:#{session_name},${SESSION_NAME}}" -F\#S
}

_if_tmux_env_var() {
    local ENV_NAME="${1}"
    tmux show-environment "${ENV_NAME}" >/dev/null 2>&1 || return 1
}

_get_tmux_env_val() {
    local ENV_NAME="${1}"
    local ENV_VAR=""

    tmux show-environment "${ENV_NAME}" >/dev/null || return 1
    ENV_VAR="$(tmux show-environment ${ENV_NAME})"

    ENV_VAL=("${(@s/=/)ENV_VAR}")
    echo ${ENV_VAL[2]}
}

_get_tmux_env_list() {
    local ENV_VAR="${1}"
    local ENV_VAL=""

    _if_tmux_env_var "${ENV_VAR}" || tmux set-environment "${ENV_VAR}"
    ENV_VAL=$(_get_tmux_env_val "${ENV_VAR}")

    LIST_VAL=("${(@s/#/)ENV_VAL}")
    echo ${LIST_VAL}
}

_add_tmux_env_list() {
    local ENV_VAR="${1}"
    local ENV_ENTRY="${2}"
    local ENV_VAL=""

    _in_tmux_env_list "${ENV_VAR}" "${ENV_ENTRY}" && return 0

    ENV_VAL="$(_get_tmux_env_val "${ENV_VAR}")#${ENV_ENTRY}"
    tmux set-environment "${ENV_VAR}" "${ENV_VAL}"
}

_del_tmux_env_list() {
    local ENV_VAR="${1}"
    local ENV_ENTRY="${2}"
    local ENV_VAL=""

    _in_tmux_env_list "${ENV_VAR}" "${ENV_ENTRY}" || return 0

    for e in $(_get_tmux_env_list "${ENV_VAR}"); do
        if [[ "${e}" != "${ENV_ENTRY}" ]]; then
            if [[ "${ENV_VAL}" == "" ]]; then
                ENV_VAL="${e}"
            else
                ENV_VAL="${ENV_VAL}#${e}"
            fi
        fi
    done

    tmux set-environment "${ENV_VAR}" "${ENV_VAL}"
}

_in_tmux_env_list() {
    local ENV_VAR="${1}"
    local ENV_ENTRY="${2}"

    local ENTRY_EXISTS=1
    for e in $(_get_tmux_env_list "${ENV_VAR}"); do
        if [[ "${e}" == "${ENV_ENTRY}" ]]; then
            ENTRY_EXISTS=0
            break
        fi
    done

    return ${ENTRY_EXISTS}
 }
