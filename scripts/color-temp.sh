#!/usr/bin/env sh

set_temperature() {
    temp=$(hyprctl hyprsunset temperature)
    new_temp=$((temp + $1))
    [ "$new_temp" -le 1000 ] && new_temp=1000
    [ "$new_temp" -ge 6500 ] && new_temp=6500
    hyprctl hyprsunset temperature "$new_temp"
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
