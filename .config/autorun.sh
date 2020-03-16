#!/bin/sh
picom -i 0.90 -b
fcitx &
flameshot &
xautolock -time 5 -locker  "i3lock -c1f67b1 -u -i ~/.config/awesome/lock.png" &
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
