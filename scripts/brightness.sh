#!/usr/bin/env sh

get_brightness() {
    brightnessctl i --machine-readable --exponent=2 | sed -E 's/.*,([0-9]+)%,.*/\1/'
}

set_brightness() {
    brightnessctl set "$1" --exponent=2 --min-value=5
    eww update brightness="$(get_brightness)"
}

case $1 in
    get) get_brightness ;;
    set) set_brightness "$2" ;;
    increase) set_brightness '+5%' ;;
    decrease) set_brightness '5%-' ;;
    blackout) brightnessctl set 0% ;;
esac
