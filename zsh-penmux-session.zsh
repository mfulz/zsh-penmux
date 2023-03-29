#!/usr/bin/env zsh
#
# Session command
#
_penmux_session() {
    if [[ "${#}" -lt 1 ]]; then
        { >&2 echo "No command given"; return 1 }
    fi

    local _cmd="${1}"
    shift 1

    case "${_cmd}" in
        create)
            _penmux_session_create ${@}
            ;;
        attach)
            _penmux_session_attach ${@}
            ;;
        destroy)
            _penmux_session_destroy ${@}
            ;;
        list)
            _penmux_session_list
            ;;
        *)
            { >&2 echo "Unknown command '${_cmd}' given"; return 1 }
            ;;
    esac
}

_penmux_session_create() {
    zparseopts -E -D \
        n=no_log -no_log=no_log

    zparseopts -F -A args -M \
        session_name: s:=session_name -session:=session_name \
        task_name: t:=task_name -task:=task_name \
        action_name: a:=action_name -action:=action_name \
        work_dir: d:=work_dir -work_dir:=work_dir \
        layout: l:=layout -layout:=layout \
        || return 1

    (($+args[-session_name])) || { >&2 echo "Session '-s | --session' is required"; return 1 }

    local _name_check="$(echo "${args[-session_name]}" | grep -e "[^A-Za-z0-9_\-]")"
    if [[ "${_name_check}" != "" ]]; then
        echo "Session name can only contain 'A-Za-z0-9-_' characters"
        return 1
    fi

    _penmux_if_session_exists "${args[-session_name]}" && {
        >&2 echo "Session '${args[-session_name]}' already exists";
        return 1
    }

    (($+args[-work_dir])) || { args[-work_dir]="$(pwd)" }

    (($+args[-layout])) && {
        local _layout_file="${CUSTOM_LAYOUTS}/${args[-layout]}.json"
        if [[ ! -e "${_layout_file}" ]]; then
            _layout_file="${PENMUX_LAYOUTS}/${args[-layout]}.json"
        fi
        if [[ ! -e "${_layout_file}" ]]; then
            { >&2 echo "Layout '${args[-layout]}' not found"; return 1 }
        fi
        args[layout_file]="${_layout_file}"

        local _sec_cmds=$(_penmux_layout_parse ${(kv)args})
        while IFS= read -r c; do
            eval "${c} || return 1"
        done < <(printf '%s\n' "${_sec_cmds}")
    } || {
        (($+args[-task_name])) || { >&2 echo "Task '-t | --task' is required"; return 1 }
        (($+args[-action_name])) || { >&2 echo "Action '-a | --action' is required"; return 1 }

        tmux new-session -dc "${args[-work_dir]}" -s "${args[-session_name]}" \; \
            set-option -q "@la-work-dir" "${args[-work_dir]}" \; \
            set-environment PENMUX_SESSION "${args[-session_name]}" \; \
            set-environment PENMUX_LOG_ACTIONS "" \; \
            rename-window "${args[-task_name]}" \; \
            select-pane -T "${args[-action_name]}"

        if [[ "${no_log}" == "" ]]; then
            local _pane="$(tmux list-panes -a -f "#{==:#{session_name},"${args[-session_name]}"}" -F "#D")"
            _penmux_logger_add -s "${args[-session_name]}" -t "${args[-task_name]}" -j "${_pane}"
        fi
    }
}

_penmux_session_attach() {
    zparseopts -F -A args -M \
        session_name: s:=session_name -session:=session_name \
        || return 1

    (($+args[-session_name])) || { >&2 echo "Session '-s | --session' is required"; return 1 }
    _penmux_if_session_valid "${args[-session_name]}" || {
        >&2 echo "Session '${args[-session_name]}' invalid"
        return 1
    }
    _penmux_if_tmux && {
        >&2 echo "Tmux detected. Please exit first."
        return 1
    }

    tmux attach-session -t "${args[-session_name]}"
}

_penmux_session_destroy() {
    zparseopts -F -A args -M \
        session_name: s:=session_name -session:=session_name \
        || return 1

    _penmux_args_find_session ${(kv)args} || return 1

    local pane_self=""
    _penmux_if_tmux && { _pane_self="$(_penmux_get_action_id)" }
    
    # stop logging if running on all panes
    for _pane in $(tmux list-panes -a -f "#{==:#{session_name},"${args[-session_name]}"}" -F "#D"); do
        #tmux select-pane -t "${_pane}"
        tmux run -t "${_pane}" "${TMUX_LOGGING_EXTENDED_TOGGLE_LOG} -a stop -p "${_pane}""
    done

    # give script stop some time
    for _pane in $(tmux list-panes -a -f "#{==:#{session_name},"${args[-session_name]}"}" -F "#D"); do
        if [[ "${_pane}" != "${_pane_self}" ]]; then
            tmux kill-pane -t "${_pane}"
        fi
    done
    if [[ "${_pane_self}" != "" ]]; then
        tmux kill-pane -t "${_pane}"
    fi

    # check if something is still left and kill
    _penmux_if_session_valid "${args[-session_name]}" || return 0
    tmux kill-session -t "${args[-session_name]}"
}

_penmux_session_list() {
    for _session in $(tmux list-sessions -F "#S"); do
        _penmux_if_session_valid "${_session}" && { echo "${_session}" }
    done
}

#
# helper functions
#
_penmux_if_session_exists() {
    local _session_name="${1}"
    local _session="$(tmux list-sessions -f "#{==:#{session_name},${_session_name}}" -F\#S)"

    if [[ "${_session}" != "" ]]; then
        return 0
    fi
    return 1
}

_penmux_if_session_valid() {
    local _session_name="${1}"
    local _check="$(tmux show-environment -t "${_session_name}" PENMUX_SESSION 2>/dev/null)"

    if [[ "${_check}" == "PENMUX_SESSION=${_session_name}" ]]; then
        return 0
    fi
    return 1
}

_penmux_if_tmux() {
    (( ${+TMUX} )) || return 1
}

_penmux_if_penmux_session() {
    _penmux_if_tmux || return 1
    tmux show-environment PENMUX_SESSION >/dev/null 2>&1 || return 1
}

_penmux_get_session_name() {
    # dont use directly
    tmux display-message -p "#{session_name}"
}
