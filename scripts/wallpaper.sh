#!/usr/bin/env sh

next_wallpaper() {
    active=$(hyprctl hyprpaper listactive | awk '{ print $3 }')
    active_index=$(hyprctl hyprpaper listloaded | grep -n "$active" | awk -F ':' '{ print $1 }')

    loaded_count=$(hyprctl hyprpaper listloaded | wc -l)
    next_index=$(( (active_index + 1) % (loaded_count + 1) ))
    if [ $next_index = 0 ]; then
        next_index=1
    fi
    new_wallpaper=$(hyprctl hyprpaper listloaded | sed -n "$next_index"p)

    hyprctl hyprpaper wallpaper "eDP-1, $new_wallpaper"
    eww reload
}

case $1 in
    next) next_wallpaper;;
esac
