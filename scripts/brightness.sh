#!/usr/bin/env sh

get_brightness() {
    brightnessctl i --machine-readable | awk -F',' '{ sub("%", ""); print $4 }'
}

set_brightness() {
    brightnessctl set "$1" --min-value=1
    eww update brightness="$(get_brightness)"
}

is_night_light() {
    [ -z "$(hyprshade current)" ] && printf false || printf true
}

toggle_night_light() {
    hyprshade toggle blue-light-filter
    eww update nightlight="$(is_night_light)"
}

case $1 in
    get) get_brightness ;;
    set) set_brightness "$2" ;;
    increase) set_brightness '+1%' ;;
    decrease) set_brightness '1%-' ;;
    blackout) brightnessctl set 0% ;;
    is-nightlight) is_night_light ;;
    toggle-nightlight) toggle_night_light ;;
esac
