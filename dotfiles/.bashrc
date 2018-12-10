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

# added by pipx (https://github.com/cs01/pipx)
export PATH="/home/sima/.local/bin:$PATH"

# Proxy settings
export http_proxy="localhost:3128"
export https_proxy=$http_proxy
export ftp_proxy=$http_proxy
export no_proxy="localhost,127.0.0.1,192.168.1.254"
