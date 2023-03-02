#!/usr/bin/env zsh
#
# Pathes
#
TMUX_LOGGING_EXTENDED_SCRIPTS=$HOME/.tmux/plugins/tmux-logging-extended/scripts
TMUX_LOGGING_EXTENDED_TOGGLE_LOG="${TMUX_LOGGING_EXTENDED_SCRIPTS}/toggle_logging.sh"

#
# Custom user file
#
CURRENT_DIR=$(exec 2>/dev/null;cd -- $(dirname "$0"); unset PWD; /usr/bin/pwd || /bin/pwd || pwd)
CUSTOM_USER_FILE="${CURRENT_DIR}/custom/zsh-penmux-user.zsh"
