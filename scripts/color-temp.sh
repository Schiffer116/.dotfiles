#!/usr/bin/env sh

set_temperature() {
    temp=$(hyprctl hyprsunset temperature)
    new_temp=$((temp + $1))
    [ "$temp" -le 1000 ] && new_temp=1000
    [ "$temp" -ge 2500 ] && new_temp=2500
    hyprctl hyprsunset temperature "$1"
    eww update color_temp=$new_temp
}

reset() {
    hyprctl hyprsunset identity
}

case $1 in
    get) get_temp ;;
    reset) reset;;
    increase) set_temperature +100;;
    decrease) set_temperature -100;;
esac
