#!/usr/bin/env zsh
#
# Pathes
#
TMUX_LOGGING_EXTENDED_SCRIPTS=$HOME/.tmux/plugins/tmux-logging-extended/scripts
TMUX_LOGGING_EXTENDED_TOGGLE_LOG="${TMUX_LOGGING_EXTENDED_SCRIPTS}/toggle_logging.sh"

CURRENT_DIR=$(exec 2>/dev/null;cd -- $(dirname "$0"); unset PWD; /usr/bin/pwd || /bin/pwd || pwd)

#
# Additional files
#
PENMUX_LAYOUTS="${CURRENT_DIR}/layouts"

#
# Tools folder
#
PENMUX_TOOLS="${CURRENT_DIR}/tools"

#
# Custom user file
#
CUSTOM_USER_FILE="${CURRENT_DIR}/custom/zsh-penmux-user.zsh"
CUSTOM_LAYOUTS="${CURRENT_DIR}/custom/layouts"
CUSTOM_TOOLS="${CURRENT_DIR}/custom/tools"
