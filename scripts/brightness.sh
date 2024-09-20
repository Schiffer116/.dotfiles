#!/usr/bin/env sh

get_brightness() {
    brightnessctl i | grep -Eo '[0-9]{1,3}%' | tr -d '%'
}

notify_user() {
    eww update show_light_slider=true
    sleep 2
    if ! pgrep -f "$0" | grep -v $$; then
        eww update show_light_slider=false
    fi
}

set_brightness() {
    brightnessctl set "$1%"
    eww update brightness="$(get_brightness)"
    notify_user
}

inc_brightness() {
    cur_light=$(get_brightness)
    if [ "$cur_light" -lt 100 ]; then
        after=$(( cur_light / 5 * 5 + 5 ))
        set_brightness "$after"
    fi
}

dec_brightness() {
    cur_light=$(get_brightness)
    after=$(( cur_light / 5 * 5 - 5 ))
    after=$(( after > 0 ? after : 1 ))
    set_brightness "$after"
}

blackout() {
    brightnessctl set 0%
}

case $1 in
    get) get_brightness ;;
    set) set_brightness "$2" ;;
    increase) inc_brightness ;;
    decrease) dec_brightness ;;
    blackout) blackout ;;
esac
