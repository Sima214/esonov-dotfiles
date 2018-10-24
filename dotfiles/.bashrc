#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

if [ -f .sensible.bash ]; then
   source .sensible.bash
fi

# Custom configuration.
alias ls='ls --color=auto'
GREEN="\[$(tput setaf 2)\]"
RESET="\[$(tput sgr0)\]"
PS1='\W \$ '

export GPG_TTY=$(tty)

# No dupplicate history entries.
#export HISTCONTROL=erasedups
