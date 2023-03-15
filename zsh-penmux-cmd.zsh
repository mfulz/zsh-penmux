#!/usr/bin/env zsh
#
# Includes
#
CURRENT_DIR=$(exec 2>/dev/null;cd -- $(dirname "$0"); unset PWD; /usr/bin/pwd || /bin/pwd || pwd)
source "${CURRENT_DIR}/zsh-penmux-defines.zsh"
source "${CURRENT_DIR}/zsh-penmux-layout.zsh"
source "${CURRENT_DIR}/zsh-penmux-args.zsh"
source "${CURRENT_DIR}/zsh-penmux-action.zsh"
source "${CURRENT_DIR}/zsh-penmux-session.zsh"
source "${CURRENT_DIR}/zsh-penmux-task.zsh"
source "${CURRENT_DIR}/zsh-penmux-logger.zsh"

#
# Main command
#
penmux() {
    if [[ "${#}" -lt 1 ]]; then
        { >&2 echo "No command given"; return 1 }
    fi

    local _cmd="${1}"
    shift 1

    case "${_cmd}" in
        session)
            _penmux_session ${@}
            ;;
        task)
            _penmux_task ${@}
            ;;
        action)
            _penmux_action ${@}
            ;;
        logger)
            _penmux_logger ${@}
            ;;
        *)
            { >&2 echo "Unknown command '${_cmd}' given"; return 1 }
            ;;
    esac
}
