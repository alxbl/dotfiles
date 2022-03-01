export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export DefaultIMModule=fcitx

[[ -f ~/.Xresources ]] && xrdb -merge ~/.Xresources
stty -xion
setxkbmap -option ctrl:nocaps

[[ -x /lib/notify-osd/notify-osd ]] && /lib/notify-osd/notify-osd &

exec i3
