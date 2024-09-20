#!/usr/bin/env sh

get_temp() {
    eww get color_temp
}

notify_user() {
    eww update show_temp_slider=true
    sleep 2
    if ! pgrep -f "$0" | grep -v $$; then
        eww update show_temp_slider=false
    fi
}

set_brightness() {
    gammastep -O "$1"
    eww update color_temp="$(get_temp)"
    notify_user
}

increase_temp() {
    cur_temp=$(get_temp)
    if [ "$cur_temp" -lt 100 ]; then
        after=$(( cur_temp / 5 * 5 + 5 ))
        set_brightness "$after"
    fi
}

decrease_temp() {
    cur_temp=$(get_temp)
    after=$(( cur_temp / 5 * 5 - 5 ))
    after=$(( after > 0 ? after : 1 ))
    set_brightness "$after"
}

blackout() {
    brightnessctl set 0%
}

case $1 in
    get) get_temp ;;
    set) set_brightness "$2" ;;
    increase) increase_temp ;;
    decrease) decrease_temp ;;
esac
