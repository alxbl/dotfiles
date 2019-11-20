export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export DefaultIMModule=fcitx

[[ -f ~/.Xresources ]] && xrdb -merge ~/.Xresources
stty -xion
setxkbmap -option ctrl:nocaps
# Start emacs server at login
emacs --daemon

exec i3
