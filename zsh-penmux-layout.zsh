#!/usr/bin/env zsh
#
# Layout json parser
#

_penmux_layout_parse() {
    local _session_name="${1}"
    local _json_file="${2}"

    local _task="$(jq ".tasks[0]" "${_json_file}")"
    local _task_name="$(jq -r ".tasks[0].name" "${_json_file}")"
    local _cs_cmd="penmux session create -s "${_session_name}" $(_penmux_layout_parse_flags "${_task}")"
    echo "${_cs_cmd}"

    _penmux_layout_parse_actions "${_session_name}" "${_task}"

    local _task_select="$(jq -r ".tasks[0].select" "${_json_file}")"
    if [[ "${_task_select}" != "" && "${_task_select}" != "null" ]]; then
        echo "tmux select-pane -t \"\$(tmux list-panes -F \"#D\" -af \"#{==:#S#W#T,"${_session_name}${_task_name}${_task_select}"}\")\""
    fi

    local count=1
    for _task_name in $(jq -r ".tasks[1:] | .[].name " "${_json_file}"); do
        _task="$(jq ".tasks[$count]" "${_json_file}")"
        local _nt_cmd="penmux task create -s "${_session_name}" $(_penmux_layout_parse_flags "${_task}")"
        echo "${_nt_cmd}"
        _penmux_layout_parse_actions "${_session_name}" "${_task}"

        local _task_select="$(jq ".tasks[0].select" "${_json_file}")"
        if [[ "${_task_select}" != "" && "${_task_select}" != "null" ]]; then
            echo "tmux select-pane -t \"\$(tmux list-panes -F \"#D\" -af \"#{==:#S#W#T,"${_session_name}${_task_name}${_task_select}"}\")\""
        fi

        (( count = count + 1 ))
    done
}

_penmux_layout_parse_actions() {
    local _session_name="${1}"
    local _entry="${2}"
    local _task_name="$(echo "${_entry}" | jq -r ".name")"
    
    local count=0
    for _action in $(echo "${_entry}" | jq -r ".actions[].action"); do
        _action="$(echo "${_entry}" | jq -r ".actions[$count]")"
        local _na_cmd="penmux action create -s "${_session_name}" -t "${_task_name}" $(_penmux_layout_parse_flags "${_action}")"
        echo "${_na_cmd}"
        (( count = count + 1))
    done
}

_penmux_layout_parse_flags() {
    local _entry="${1}"

    local _name="$(echo "${_entry}" | jq -r ".name")"
    local _action="$(echo "${_entry}" | jq -r ".action")"
    local _log="$(echo "${_entry}" | jq -r ".log")"
    local _switch="$(echo "${_entry}" | jq -r ".switch")"
    local _split="$(echo "${_entry}" | jq -r ".split")"
    local _full="$(echo "${_entry}" | jq -r ".full")"
    local _active="$(echo "${_entry}" | jq -r ".active")"
    
    local _flags=""

    if [[ "${_name}" != "" && "${_name}" != "null" ]]; then
        _flags="${_flags} -t "${_name}""
    fi

    if [[ "${_action}" != "" && "${_action}" != "null" ]]; then
        _flags="${_flags} -a "${_action}""
    fi

    if [[ "${_log}" != "yes" ]]; then
        _flags="${_flags} -n"
    fi

    if [[ "${_switch}" == "yes" ]]; then
        _flags="${_flags} -b"
    fi

    if [[ "${_split}" == "v" || "${_split}" == "h" ]]; then
        _flags="${_flags} -${_split}"
    fi

    if [[ "${_full}" == "yes" ]]; then
        _flags="${_flags} -f"
    fi

    if [[ "${_active}" == "no" ]]; then
        _flags="${_flags} -d"
    fi

    echo "${_flags}"
}

_layout_parse_tasks() {
    local SESSION_NAME="${1}"
    local JSON_FILE="${2}"

    local _task="$(jq ".tasks[0]" "${JSON_FILE}")"
    local _task_name="$(jq -r ".tasks[0].name" "${JSON_FILE}")"
    local _cs_cmd="penmux_create_session -s "${SESSION_NAME}" $(_layout_parse_flags "${_task}")"
    echo "${_cs_cmd}"

    _layout_parse_actions "${SESSION_NAME}" "${_task}"

    local _task_select="$(jq -r ".tasks[0].select" "${JSON_FILE}")"
    if [[ "${_task_select}" != "" && "${_task_select}" != "null" ]]; then
        echo "tmux select-pane -t \"\$(tmux list-panes -F \"#D\" -af \"#{==:#S#W#T,"${SESSION_NAME}${_task_name}${_task_select}"}\")\""
    fi

    local count=1
    for _task_name in $(jq -r ".tasks[1:] | .[].name " "${JSON_FILE}"); do
        _task="$(jq ".tasks[$count]" "${JSON_FILE}")"
        local _nt_cmd="penmux_new_task -s "${SESSION_NAME}" $(_layout_parse_flags "${_task}")"
        echo "${_nt_cmd}"
        _layout_parse_actions "${SESSION_NAME}" "${_task}"

        local _task_select="$(jq ".tasks[0].select" "${JSON_FILE}")"
        if [[ "${_task_select}" != "" && "${_task_select}" != "null" ]]; then
            echo "tmux select-pane -t \"\$(tmux list-panes -F \"#D\" -af \"#{==:#S#W#T,"${SESSION_NAME}${_task_name}${_task_select}"}\")\""
        fi

        (( count = count + 1 ))
    done
}

_layout_parse_actions() {
    local SESSION_NAME="${1}"
    local _entry="${2}"
    local _task_name="$(echo "${_entry}" | jq -r ".name")"
    
    local count=0
    for _action in $(echo "${_entry}" | jq -r ".actions[].action"); do
        _action="$(echo "${_entry}" | jq -r ".actions[$count]")"
        local _na_cmd="penmux_new_action -s "${SESSION_NAME}" -t "${_task_name}" $(_layout_parse_flags "${_action}")"
        echo "${_na_cmd}"
        (( count = count + 1))
    done
}

_layout_parse_flags() {
    local _entry="${1}"

    local _name="$(echo "${_entry}" | jq -r ".name")"
    local _action="$(echo "${_entry}" | jq -r ".action")"
    local _log="$(echo "${_entry}" | jq -r ".log")"
    local _switch="$(echo "${_entry}" | jq -r ".switch")"
    local _split="$(echo "${_entry}" | jq -r ".split")"
    local _full="$(echo "${_entry}" | jq -r ".full")"
    local _active="$(echo "${_entry}" | jq -r ".active")"
    
    local _flags=""

    if [[ "${_name}" != "" && "${_name}" != "null" ]]; then
        _flags="${_flags} -t "${_name}""
    fi

    if [[ "${_action}" != "" && "${_action}" != "null" ]]; then
        _flags="${_flags} -a "${_action}""
    fi

    if [[ "${_log}" != "yes" ]]; then
        _flags="${_flags} -n"
    fi

    if [[ "${_switch}" == "yes" ]]; then
        _flags="${_flags} -b"
    fi

    if [[ "${_split}" == "v" || "${_split}" == "h" ]]; then
        _flags="${_flags} -${_split}"
    fi

    if [[ "${_full}" == "yes" ]]; then
        _flags="${_flags} -f"
    fi

    if [[ "${_active}" == "no" ]]; then
        _flags="${_flags} -d"
    fi

    echo "${_flags}"
}
