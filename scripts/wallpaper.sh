#!/usr/bin/env sh

next_wallpaper() {
    active=$(hyprctl hyprpaper listactive | awk '{ print $3 }')

    all_wallpapers=$(find "$HOME/Pictures/arts/" -type f | sort)

    next_wallpaper=$(
        echo "$all_wallpapers" | \
        grep --line-number --after-context=1 "$active" | \
        tail -n 1 | \
        awk -F '-' "
            { sub(/^[0-9]+-/, \"\"); print }
            END { println \"$(echo "$all_wallpapers" | tail -n 1)\" }
        "
    )

    if [ -z "$next_wallpaper" ]; then
        next_wallpaper=$(echo "$all_wallpapers" | head -n 1)
    fi

    hyprctl hyprpaper reload "eDP-1, $next_wallpaper"
    eww reload
}

case $1 in
    next) next_wallpaper;;
esac
