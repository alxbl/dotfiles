[[ -f ~/.Xresources ]] && xrdb -merge ~/.Xresources
redshift -l 0:0 -O 3500K &
exec awesome
