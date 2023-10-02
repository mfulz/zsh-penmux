#!/usr/bin/env zsh
#
# Layout json parser
#

_penmux_layout_parse() {
    set -A args ${(kv)@}
    local _cs_cmd_flags=" --work_dir \"${args[-work_dir]}\""

    local _task="$(jq ".tasks[0]" "${args[layout_file]}")"
    local _task_name="$(jq -r ".tasks[0].name" "${args[layout_file]}")"
    _task_name="$(_layout_parse_repl "${_task_name}" "${args[-repl]}")"
    local _cs_cmd="penmux session create -s "${args[-session_name]}" $(_penmux_layout_parse_flags "${_task}" "${_task_name}" "${args[-repl]}")"

    (($+args[-no_log])) && { _cs_cmd_flags="${_cs_cmd_flags} --no_log" }

    echo "${_cs_cmd} ${_cs_cmd_flags}"

    _penmux_layout_parse_actions "${args[-session_name]}" "${_task}" "${_task_name}" "${args[-repl]}"

    local _task_select="$(jq -r ".tasks[0].select" "${args[layout_file]}")"
    if [[ "${_task_select}" != "" && "${_task_select}" != "null" ]]; then
        echo "tmux select-pane -t \"\$(tmux list-panes -F \"#D\" -af \"#{==:#S#W#T,"${args[-session_name]}${_task_name}${_task_select}"}\")\""
    fi

    local count=1
    for _task_name in $(jq -r ".tasks[1:] | .[].name " "${args[layout_file]}"); do
        _task="$(jq ".tasks[$count]" "${args[layout_file]}")"
        _task_name="$(_layout_parse_repl "${_task_name}" "${args[-repl]}")"
        local _nt_cmd="penmux task create -s "${args[-session_name]}" $(_penmux_layout_parse_flags "${_task}" "${_task_name}" "${args[-repl]}")"
        echo "${_nt_cmd}"
        _penmux_layout_parse_actions "${args[-session_name]}" "${_task}" "${_task_name}" "${args[-repl]}"

        local _task_select="$(jq ".tasks[0].select" "${args[layout_file]}")"
        if [[ "${_task_select}" != "" && "${_task_select}" != "null" ]]; then
            echo "tmux select-pane -t \"\$(tmux list-panes -F \"#D\" -af \"#{==:#S#W#T,"${args[-session_name]}${_task_name}${_task_select}"}\")\""
        fi

        (( count = count + 1 ))
    done
}

_penmux_layout_parse_actions() {
    local _session_name="${1}"
    local _entry="${2}"
    local _task_name="${3}"
    local _repl_val="${4}"

    if [[ -z "${_task_name}" ]]; then
      _task_name="$(echo "${_entry}" | jq -r ".name")"
    fi
    
    local count=0
    for _action in $(echo "${_entry}" | jq -r ".actions[].action"); do
        _action="$(echo "${_entry}" | jq -r ".actions[$count]")"
        _action="$(_layout_parse_repl "${_action}" "${_repl_val}")"
        local _na_cmd="penmux action create -s "${_session_name}" -t "${_task_name}" $(_penmux_layout_parse_flags "${_action}")"
        echo "${_na_cmd}"

        local _action_select="$(echo "${_action}" | jq -r ".select")"
        _action_select="$(_layout_parse_repl "${_action_select}" "${_repl_val}")"
        if [[ "${_action_select}" != "" && "${_action_select}" != "null" ]]; then
          echo "tmux select-pane -t \"\$(tmux list-panes -F \"#D\" -af \"#{==:#S#W#T,"${_session_name}${_task_name}${_action_select}"}\")\""
        fi

        (( count = count + 1))
    done
}

_penmux_layout_parse_flags() {
    local _entry="${1}"
    local _name="${2}"
    local _repl_val="${3}"

    if [[ -z "${_name}" ]]; then
      _name="$(echo "${_entry}" | jq -r ".name")"
    fi
    local _action="$(echo "${_entry}" | jq -r ".action")"
    _action="$(_layout_parse_repl "${_action}" "${_repl_val}")"
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
    local _repl_val="${3}"

    local _task="$(jq ".tasks[0]" "${JSON_FILE}")"
    local _task_name=_layout_parse_repl "$(jq -r ".tasks[0].name" "${JSON_FILE}")" "${_repl_val}"
    local _cs_cmd="penmux_create_session -s "${SESSION_NAME}" $(_layout_parse_flags "${_task}")"
    echo "${_cs_cmd}"

    _layout_parse_actions "${SESSION_NAME}" "${_task}" "${_task_name}"

    local _task_select="$(jq -r ".tasks[0].select" "${JSON_FILE}")"
    if [[ "${_task_select}" != "" && "${_task_select}" != "null" ]]; then
        echo "tmux select-pane -t \"\$(tmux list-panes -F \"#D\" -af \"#{==:#S#W#T,"${SESSION_NAME}${_task_name}${_task_select}"}\")\""
    fi

    local count=1
    for _task_name in _layout_parse_repl $(jq -r ".tasks[1:] | .[].name " "${JSON_FILE}") "${_repl_val}"; do
        _task="$(jq ".tasks[$count]" "${JSON_FILE}")"
        local _nt_cmd="penmux_new_task -s "${SESSION_NAME}" $(_layout_parse_flags "${_task}")"
        echo "${_nt_cmd}"
        _layout_parse_actions "${SESSION_NAME}" "${_task}" "${_task_name}"

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
    local _task_name="${3}"

    # local _task_name="$(echo "${_entry}" | jq -r ".name")"
    
    local count=0
    for _action in $(echo "${_entry}" | jq -r ".actions[].action"); do
        echo "${_action}" >> /tmp/pm.txt
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

_layout_get_repl_list() {
  local _repl_val="${1}"
  local _repl_list=""

  _repl_list=("${(@s/#/)_repl_val}")
  echo ${_repl_list}
}

_layout_parse_repl() {
  local _act_val="${1}"
  local _repl_val="${2}"

  if [[ -z "${_repl_val}" ]]; then
    echo -n "${_act_val}"
    return
  fi

  for e in $(_layout_get_repl_list "${_repl_val}"); do
    local _entry_split=("${(@s/=/)e}")
    local _k="${_entry_split[1]}"
    local _v="${_entry_split[2]}"

    if [[ "${_act_val}" == "${_k}" ]]; then
      echo -n "${_v}"
      return
    fi
  done

  echo -n "${_act_val}"
}
