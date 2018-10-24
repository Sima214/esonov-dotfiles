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
PS1='\W \$ '

# Fix environment.
export GPG_TTY=$(tty)
