#!/usr/bin/env sh

get_brightness() {
    brightnessctl i --machine-readable --exponent=2 | sed -E 's/.*,([0-9]+)%,.*/\1/'
}

notify_user() {
    eww update show_light_slider=true
    sleep 2
    if ! pgrep -f "$0" | grep -v $$; then
        eww update show_light_slider=false
    fi
}

set_brightness() {
    brightnessctl set "$1" --exponent=2 --min-value=5
    eww update brightness="$(get_brightness)"
    notify_user
}

case $1 in
    get) get_brightness ;;
    set) set_brightness "$2" ;;
    increase) set_brightness '+5%' ;;
    decrease) set_brightness '5%-' ;;
    blackout) brightnessctl set 0% ;;
esac
