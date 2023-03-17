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
    return 0
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
        args[-task_id]="$(_penmux_get_task_id_by_name "${args[-session_name]}" "${args[-task_name]}")"
    elif (($+args[-task_id])); then
        args[-task_name]="$(_penmux_get_task_name_by_id "${args[-task_id]}")"
        _penmux_if_task_name_unique "${args[-session_name]}" "${args[-task_name]}" || {
            >&2 echo "Task id '${args[-task_id]}' invalid"
            return 1
        }
    else
        _penmux_if_penmux_session || { >&2 echo "No pemnux session"; return 1 }
        args[-task_name]="$(_penmux_get_task_name)"
        args[-task_id]="$(_penmux_get_task_id)"
    fi
    return 0
}

_penmux_args_check_new_task() {
    set -A args ${(kv)@}

    if (($+args[-new_task_name])); then
        _penmux_if_task_exists "${args[-session_name]}" "${args[-new_task_name]}" || {
            >&2 echo "Task '${args[-new_task_name]}' already existing"
            return 1
        }

        local _task_name="${args[-task_name]}"
        args[-task_name]="${args[-new_task_name]}"
        _penmux_args_action_unique ${(kv)args} || { args[-task_name]="${_task_name}"; return 1 }
        args[-task_name]="${_task_name}"
    else
        >&2 echo "New task name '-n | --new_name' is required"
        return 1
    fi
    return 0
}

_penmux_args_find_action() {
    set -A args ${(kv)@}

    if (($+args[-action_name])) && (($+args[-action_id])); then
        >&2 echo "User either action name '-a | --action' or action id '-j | --action_id' not both"
        return 1
    elif (($+args[-action_name])); then
        args[-action_id]="$(_penmux_get_action_id_by_name "${args[-session_name]}" "${args[-task_id]}" "${args[-action_name]}")"
    elif (($+args[-action_id])); then
        args[-action_name]="$(_penmux_get_action_name_by_id "${args[-action_id]}")"
        _penmux_if_action_name_unique "${args[-session_name]}" "${args[-task_name]}" "${args[-action_name]}" || {
            >&2 echo "Action id '${args[-action_id]}' invalid"
            return 1
        }
    else
        _penmux_if_penmux_session || { >&2 echo "No pemnux session"; return 1 }
        args[-action_name]="$(_penmux_get_action_name)"
        args[-action_id]="$(_penmux_get_action_id)"
    fi
    return 0
}

_penmux_args_check_new_action() {
    set -A args ${(kv)@}

    if (($+args[-new_action_name])); then
        _penmux_if_action_duplicate "${args[-session_name]}" "${args[-task_name]}" "${args[-new_action_name]}" && {
            >&2 echo "Action '${args[-new_action_name]}' already exists under Task '${args[-task_name]}'"
            return 1
        }
    else
        >&2 echo "New action name '-n | --new_name' is required"
        return 1
    fi
    return 0
}

_penmux_args_action_unique() {
    set -A args ${(kv)@}

    if (($+args[-action_name])) && (($+args[-action_id])); then
        _penmux_if_action_duplicate_by_id "${args[-action_id]}" "${args[-action_name]}" && {
            >&2 echo "Action '${args[-action_name]}' already exists"
            return 1
        }
    elif (($+args[-action_name])); then
        _penmux_if_action_duplicate "${args[-session_name]}" "${args[-task_name]}" "${args[-action_name]}" && {
            >&2 echo "Action '${args[-action_name]}' already exists"
            return 1
        }
    else
        _penmux_if_action_duplicate_by_task "${args[-session_name]}" "${args[-task_name]}" && {
            >&2 echo "Some actions already exists"
            return 1
        }
    fi
    return 0
}
