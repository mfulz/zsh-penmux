#!/usr/bin/env zsh
#
# Includes
#
CURRENT_DIR=$(exec 2>/dev/null;cd -- $(dirname "$0"); unset PWD; /usr/bin/pwd || /bin/pwd || pwd)
source "${CURRENT_DIR}/zsh-penmux-cmd.zsh"

#
# Aliases
#
alias pmSC='penmux session create'
alias pmSA='penmux session attach'
alias pmSD='penmux session destroy'
alias pmTC='penmux task create'
alias pmAC='penmux action create'
alias pmLT='penmux logger toggle'
alias pmLA='penmux logger add'
alias pmLR='penmux logger remove'
alias pmLS='penmux logger start'
alias pmLE='penmux logger stop'

