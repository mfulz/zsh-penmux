#!/usr/bin/env zsh
#
# Task command
#
_penmux_task() {
    if [[ "${#}" -lt 1 ]]; then
        { >&2 echo "No command given"; return 1 }
    fi

    local _cmd="${1}"
    shift 1

    case "${_cmd}" in
        create)
            _penmux_task_create ${@}
            ;;
        rename)
            _penmux_task_rename ${@}
            ;;
        *)
            { >&2 echo "Unknown command '${_cmd}' given"; return 1 }
            ;;
    esac
}

_penmux_task_create() {
    zparseopts -E -D -a tmux_flags \
        n=no_log -no_log=no_log \
        -stop_log=stop_log \
        d=tmux_flags

    zparseopts -F -A args -M \
        session_name: s:=session_name -session:=session_name \
        task_name: t:=task_name -task:=task_name \
        action_name: a:=action_name -action:=action_name \
        || return 1

    _penmux_args_find_session ${(kv)args} || return 1
    _penmux_args_action_unique ${(kv)args} || return 1

    local _pane="$(tmux new-window ${=tmux_flags} -t "${args[-session_name]}" -n "${args[-task_name]}" -F "#D" -P)"
    tmux select-pane -t "${_pane}" -T "${args[-action_name]}"

    if [[ "${no_log}" == "" ]]; then
        _penmux_logger_add -s "${args[-session_name]}" -t "${args[-task_name]}" -j "${_pane}"
    fi
}

_penmux_task_rename() {
    zparseopts -F -A args -M \
        session_name: s:=session_name -session:=session_name \
        task_name: t:=task_name -task:=task_name \
        task_id: i:=task_id -task_id:=task_id \
        new_task_name: n:=task_id -new_name:=new_task_name \
        || return 1

    (($+args[-new_task_name])) || { >&2 echo "New task name '-n | --new_name' is required"; return 1 }
    _penmux_args_find_session ${(kv)args} || return 1
    _penmux_args_find_task ${(kv)args} || return 1
    _penmux_args_action_unique ${(kv)args} || return 1

    tmux rename-window -t "${args[-task_id]}" "${args[-new_name]}"
}

#
# helper functions
#
_penmux_if_task_name_unique() {
    local _session_name="${1}"
    local _task_name="${2}"

    local _count=$(tmux list-windows -af "#{==:#S#W,${_session_name}${_task_name}}" | wc -l)

    if [[ "${_count}" -eq 1 ]]; then
        return 0
    fi
    return 1
}

_penmux_get_task_name_by_id() {
    local _task_id="${1}"

    echo "$(tmux list-windows -aF "#W" -f "#{==:#{window_id},${_task_id}}")"
}

_penmux_get_task_id_by_name() {
    local _session_name="${1}"
    local _task_name="${2}"

    echo "$(tmux list-windows -aF "#{window_id}" -f "#{==:#S#W,${_session_name}${_task_name}}")"
}

_penmux_get_task_name() {
    # dont use directly
    tmux display-message -p "#{window_name}"
}

_penmux_get_task_id() {
    tmux display-message -p "#{window_id}"
}

