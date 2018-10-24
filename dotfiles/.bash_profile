#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

# Auto start window manager.
if [ ! -f ~/no_gui ]; then
    if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then
        echo "Starting X server..."
        exec startx
    fi
else
    echo "Starting headless session..."
    sleep 1
    rm ~/no_gui
fi
