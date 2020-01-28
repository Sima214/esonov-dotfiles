# Prime configuration.
# xrandr --setprovideroutputsource modesetting NVIDIA-0
xrandr --output eDP-1-1 --mode 1366x768 --rate 60
# Fix cursor.
sleep 0.6 & xsetroot -cursor_name left_ptr
# Mostly to support transparent windows.
compton --config /home/sima/.compton.conf -b
# Seems important.
/etc/X11/xinit/xinitrc.d/50-systemd-user.sh
# Start awesome.
if [ -f "/tmp/.awesomewm.log" ]; then
  rm /tmp/.awesomewm.log.gz
  gzip -9 /tmp/.awesomewm.log
fi
awesome &> /tmp/.awesomewm.log
# Make sure compton is dead when shutting down. Sometimes it causes problems.
killall compton
