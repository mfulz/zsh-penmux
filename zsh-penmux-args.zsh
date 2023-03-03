#!/usr/bin/env zsh
#
# Argument helper functions
#
_penmux_args_find_session() {
    set -A args ${(kv)@}

    (($+args[-session_name])) || {
        _penmux_if_penmux_session || { >&2 echo "No penmux session"; return 1 }
        args[-session_name]="$(_penmux_get_session_name)"
    }
    _penmux_if_session_valid "${args[-session_name]}" || {
        >&2 "Session '${args[-session_name]}' invalid"
        return 1
    }
}

_penmux_args_find_task() {
    set -A args ${(kv)@}

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
}
