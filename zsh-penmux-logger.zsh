#!/usr/bin/env zsh
#
# Logger command
#
_penmux_logger() {
    if [[ "${#}" -lt 1 ]]; then
        { >&2 echo "No command given"; return 1 }
    fi

    local _cmd="${1}"
    shift 1

    case "${_cmd}" in
        add)
            _penmux_logger_add ${@}
            ;;
        remove)
            _penmux_logger_remove ${@}
            ;;
        start)
            _penmux_logger_start ${@}
            ;;
        stop)
            _penmux_logger_stop ${@}
            ;;
        toggle)
            _penmux_logger_toggle ${@}
            ;;
        *)
            { >&2 echo "Unknown command '${_cmd}' given"; return 1 }
            ;;
    esac
}

_penmux_logger_add() {
    zparseopts -F -A args -M \
        session_name: s:=session_name -session:=session_name \
        task_name: t:=task_name -task:=task_name \
        task_id: i:=task_id -task_id:=task_id \
        action_name: a:=action_name -action:=action_name \
        action_id: j:=action_id -action_id:=action_name \
        || return 1


    _penmux_args_find_session ${(kv)args} || return 1
    _penmux_args_find_task ${(kv)args} 2>/dev/null
    _penmux_args_find_action ${(kv)args} 2>/dev/null

    _penmux_add_tmux_env_list "${args[-session_name]}" PENMUX_LOG_ACTIONS "${args[-action_id]}"
}

_penmux_logger_remove() {
    zparseopts -F -A args -M \
        session_name: s:=session_name -session:=session_name \
        task_name: t:=task_name -task:=task_name \
        task_id: i:=task_id -task_id:=task_id \
        action_name: a:=action_name -action:=action_name \
        action_id: j:=action_id -action_id:=action_name \
        || return 1


    _penmux_args_find_session ${(kv)args} || return 1
    _penmux_args_find_task ${(kv)args} 2>/dev/null
    _penmux_args_find_action ${(kv)args} 2>/dev/null

    _penmux_del_tmux_env_list "${args[-session_name]}" PENMUX_LOG_ACTIONS "${args[-action_id]}"
}

_penmux_logger_start() {
    zparseopts -F -A args -M \
        session_name: s:=session_name -session:=session_name \
        || return 1

    # local _act_pane_id="$(tmux list-panes -F '#D' -af "#{==:#S1,"${session_name}#{pane_active}"}")"

    _penmux_args_find_session ${(kv)args} || return 1
    _penmux_args_find_task ${(kv)args} 2>/dev/null
    _penmux_args_find_action ${(kv)args} 2>/dev/null

    for _pane in $(_penmux_get_tmux_env_list "${args[-session_name]}" PENMUX_LOG_ACTIONS); do
        if (($+args[-action_id])); then
            if [[ "${_pane}" == "${args[-action_id]}" ]]; then
                local _self="${_pane}"
                continue
            fi
        fi
        tmux run -t "${_pane}" "${TMUX_LOGGING_EXTENDED_TOGGLE_LOG} -a start -p "${_pane}""
    done
    if [[ "${_self}" != "" ]]; then
        tmux run -t "${_self}" "${TMUX_LOGGING_EXTENDED_TOGGLE_LOG} -a start -p "${_self}""
    fi

    # tmux select-pane -t "${_act_pane_id}"
}

_penmux_logger_stop() {
    zparseopts -F -A args -M \
        session_name: s:=session_name -session:=session_name \
        || return 1


    _penmux_args_find_session ${(kv)args} || return 1
    _penmux_args_find_task ${(kv)args} 2>/dev/null
    _penmux_args_find_action ${(kv)args} 2>/dev/null

    for _pane in $(_penmux_get_tmux_env_list "${args[-session_name]}" PENMUX_LOG_ACTIONS); do
        if (($+args[-action_id])); then
            if [[ "${_pane}" == "${args[-action_id]}" ]]; then
                local _self="${_pane}"
                continue
            fi
        fi
        tmux run -t "${_pane}" "${TMUX_LOGGING_EXTENDED_TOGGLE_LOG} -a stop -p "${_pane}""
    done
    if [[ "${_self}" != "" ]]; then
        tmux run -t "${args[-action_id]}" "${TMUX_LOGGING_EXTENDED_TOGGLE_LOG} -a stop -p "${args[-action_id]}""
    fi
}

_penmux_logger_toggle() {
    zparseopts -F -A args -M \
        session_name: s:=session_name -session:=session_name \
        || return 1


    _penmux_args_find_session ${(kv)args} || return 1
    _penmux_args_find_task ${(kv)args} 2>/dev/null
    _penmux_args_find_action ${(kv)args} 2>/dev/null

    for _pane in $(_penmux_get_tmux_env_list "${args[-session_name]}" PENMUX_LOG_ACTIONS); do
        if (($+args[-action_id])); then
            if [[ "${_pane}" == "${args[-action_id]}" ]]; then
                local _self="${_pane}"
                continue
            fi
        fi
        tmux run -t "${_pane}" "${TMUX_LOGGING_EXTENDED_TOGGLE_LOG} -p "${_pane}""
    done
    if [[ "${_self}" != "" ]]; then
        tmux run -t "${args[-action_id]}" "${TMUX_LOGGING_EXTENDED_TOGGLE_LOG} -p "${args[-action_id]}""
    fi
}

#
# helper functions
#
_penmux_if_tmux_env_var() {
    local _session_name="${1}"
    local _env_name="${2}"
    tmux show-environment -t "${_session_name}" "${_env_name}" >/dev/null 2>&1 || return 1
}

_penmux_get_tmux_env_val() {
    local _session_name="${1}"
    local _env_name="${2}"
    local _env_var=""

    tmux show-environment -t "${_session_name}" "${_env_name}" >/dev/null || return 1
    _env_var="$(tmux show-environment -t "${_session_name}" "${_env_name}")"

    _env_val=("${(@s/=/)_env_var}")
    echo ${_env_val[2]}
}

_penmux_set_tmux_env_val() {
    local _session_name="${1}"
    local _env_var="${2}"
    local _env_val="${3}"

    tmux set-environment -t "${_session_name}" "${_env_var}" "${_env_val}"
}

_penmux_unset_tmux_env_val() {
    local _session_name="${1}"
    local _env_var="${2}"

    tmux set-environment -t "${_session_name}" -u "${_env_var}"
}

_penmux_get_task_env_val() {
    local _session_name="${1}"
    local _task_name="${2}"
    local _env_name="${3}"
    local _env_var=""

    tmux show-environment -t "${_session_name}" "${_task_name}:::${_env_name}" >/dev/null || return 1
    _env_var="$(tmux show-environment -t "${_session_name}" "${_task_name}:::${_env_name}")"

    _env_val=("${(@s/=/)_env_var}")
    echo ${_env_val[2]}
}

_penmux_set_task_env_val() {
    local _session_name="${1}"
    local _task_name="${2}"
    local _env_var="${3}"
    local _env_val="${4}"

    tmux set-environment -t "${_session_name}" "${_task_name}:::${_env_var}" "${_env_val}"
}

_penmux_unset_task_env_val() {
    local _session_name="${1}"
    local _task_name="${2}"
    local _env_var="${3}"

    tmux set-environment -t "${_session_name}" -u "${_task_name}:::${_env_var}"
}

_penmux_get_action_env_val() {
    local _session_name="${1}"
    local _task_name="${2}"
    local _action_name="${3}"
    local _env_name="${4}"
    local _env_var=""

    tmux show-environment -t "${_session_name}" "${_task_name}:::${_action_name}:::${_env_name}" >/dev/null || return 1
    _env_var="$(tmux show-environment -t "${_session_name}" "${_task_name}:::${_action_name}:::${_env_name}")"

    _env_val=("${(@s/=/)_env_var}")
    echo ${_env_val[2]}
}

_penmux_set_task_env_val() {
    local _session_name="${1}"
    local _task_name="${2}"
    local _action_name="${3}"
    local _env_var="${4}"
    local _env_val="${5}"

    tmux set-environment -t "${_session_name}" "${_task_name}:::${_action_name}:::${_env_var}" "${_env_val}"
}

_penmux_unset_task_env_val() {
    local _session_name="${1}"
    local _task_name="${2}"
    local _action_name="${3}"
    local _env_var="${4}"

    tmux set-environment -t "${_session_name}" -u "${_task_name}:::${_action_name}:::${_env_var}"
}

_penmux_get_tmux_env_list() {
    local _session_name="${1}"
    local _env_var="${2}"
    local _env_val=""

    _penmux_if_tmux_env_var "${_session_name}" "${_env_var}" || tmux set-environment -t "${_session_name}" "${_env_var}"
    _env_val=$(_penmux_get_tmux_env_val "${_session_name}" "${_env_var}")

    _list_val=("${(@s/#/)_env_val}")
    echo ${_list_val}
}

_penmux_add_tmux_env_list() {
    local _session_name="${1}"
    local _env_var="${2}"
    local _env_entry="${3}"
    local _env_val=""

    _penmux_in_tmux_env_list "${_session_name}" "${_env_var}" "${_env_entry}" && return 0

    _env_val="$(_penmux_get_tmux_env_val "${_session_name}" "${_env_var}")#${_env_entry}"
    tmux set-environment -t "${_session_name}" "${_env_var}" "${_env_val}"
}

_penmux_del_tmux_env_list() {
    local _session_name="${1}"
    local _env_var="${2}"
    local _env_entry="${3}"
    local _env_val=""

    _penmux_in_tmux_env_list "${_session_name}" "${_env_var}" "${_env_entry}" || return 0

    for e in $(_penmux_get_tmux_env_list "${_session_name}" "${_env_var}"); do
        if [[ "${e}" != "${_env_entry}" ]]; then
            if [[ "${_env_val}" == "" ]]; then
                _env_val="${e}"
            else
                _env_val="${_env_val}#${e}"
            fi
        fi
    done

    tmux set-environment -t "${_session_name}" "${_env_var}" "${_env_val}"
}

_penmux_in_tmux_env_list() {
    local _session_name="${1}"
    local _env_var="${2}"
    local _env_entry="${3}"

    local _entry_exists=1
    for e in $(_penmux_get_tmux_env_list "${_session_name}" "${_env_var}"); do
        if [[ "${e}" == "${_env_entry}" ]]; then
            _entry_exists=0
            break
        fi
    done

    return ${_entry_exists}
}
