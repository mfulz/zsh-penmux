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
}

_penmux_logger_remove() {
}

_penmux_logger_start() {
}

_penmux_logger_stop() {
}

_penmux_logger_toggle() {
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
    _penmux_if_action_duplicate "${args[-session_name]}" "${args[-task_name]}" "${args[-action_name]}" && {
        >&2 echo "Action '${args[-action_name]}' already exists"
        return 1
    }

    local _pane="$(tmux new-window ${=tmux_flags} -t "${args[-session_name]}" -n "${args[-task_name]}" -F "#D" -P)"
    tmux select-pane -t "${_pane}" -T "${args[-action_name]}"

    if [[ "${no_log}" != "" ]]; then
        # TODO: use action cmd
        _add_tmux_env_list "${args[-session_name]}" PENMUX_LOG_ACTIONS "${_pane}"
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

    if (($+args[-task_name])) && (($+args[-task_id])); then
        >&2 echo "User either task name '-t | --task_name' or task id '-i | --task_id' not both"
        return 1
    elif (($+args[-task_name])); then
        _penmux_if_task_name_unique "${args[-session_name]}" "${args[-task_name]}" || {
            >&2 echo "Task '${args[-task_name]}' not unique or not existing"
            return 1
        }
    elif (($+args[-task_id])); then
        _penmux_get_task_name_by_id "${args[-task_id]}"
        _penmux_if_task_name_unique "${args[-session_name]}" "${args[-task_name]}" || {
            >&2 echo "Task id '${args[-task_id]}' invalid"
            return 1
        }
     else
        _penmux_if_session || { >&2 echo "No pemnux session"; return 1 }
        args[-task_name]="$(_penmux_get_task_name)"
        args[-task_id]="$(_penmux_get_task_id)"
    fi

    _penmux_if_action_duplicate_by_task "${args[-session_name]}" "${args[-task_name]}" "${args[-action_name]}" && {
        >&2 echo "Action '${args[-action_name]}' already exists"
        return 1
    }

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

_penmux_get_task_name() {
    # dont use directly
    tmux display-message -p "#{window_name}"
}

_penmux_get_task_id() {
    tmux display-message -p "#{window_id}"
}
