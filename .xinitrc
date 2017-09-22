export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export DefaultIMModule=fcitx

[[ -f ~/.Xresources ]] && xrdb -merge ~/.Xresources
redshift -l 0:0 -O 3500K &
exec awesome
