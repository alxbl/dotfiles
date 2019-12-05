#!/bin/sh
compton -i 0.90 &
fcitx &
flameshot &
xautolock -time 5 -locker  "i3lock -c1f67b1 -u -i ~/.config/awesome/lock.png" &
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
