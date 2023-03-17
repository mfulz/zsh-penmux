#!/usr/bin/env zsh
#
# Includes
#
CURRENT_DIR=$(exec 2>/dev/null;cd -- $(dirname "$0"); unset PWD; /usr/bin/pwd || /bin/pwd || pwd)
source "${CURRENT_DIR}/zsh-penmux-cmd.zsh"

#
# Aliases
#
alias pmCS='penmux_create_session'
alias pmAS='penmux_attach_session'
alias pmES='penmux_end_session'
alias pmNT='penmux_new_task'
alias pmNA='penmux_new_action'
alias pmTA='penmux_toggle_log_action'
alias pmAA='penmux_add_log_action'
alias pmDA='penmux_del_log_action'
alias pmGA='penmux_get_log_action'
alias pmTL='penmux_toggle_log'
alias pmSL='penmux_start_log'
alias pmEL='penmux_stop_log'

