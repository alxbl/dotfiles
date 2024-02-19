#!/bin/sh
picom -b
fcitx &
flameshot &
xautolock -time 5 -locker  "i3lock -c1f67b1 -u -i ~/.config/awesome/lock.png" &
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
polybar &

LAYOUT="$HOME/.screenlayout/default.sh"
if [ -x $LAYOUT]; then
    $LAYOUT
fi
