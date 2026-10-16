#!/usr/bin/env sh

get_temp() {
    hyprctl hyprsunset temperature
}

# The bar reads `get` once when eww starts (color_temp in bar/widgets.yuck) and each change
# is pushed here, since hyprsunset has no change events.
set_temperature() {
    temp=$(get_temp)
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
