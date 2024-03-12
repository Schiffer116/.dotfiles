#!/usr/bin/env sh

get_brightness() {
    brightnessctl i | grep -Eo '[0-9]{1,3}%' | tr -d '%'
}

notify_user() {
    if [ "$(eww get show_light_slider)" = "false" ]; then
        eww update show_light_slider=true
    fi
    pgrep brightness.sh | grep -v $$ | xargs kill 2> /dev/null
    sleep 2 && eww update show_light_slider=false &
}

set_brightness() {
    brightnessctl set "$1%"
    notify_user
}

inc_brightness() {
    cur_light=$(get_brightness)
    if [ "$cur_light" -lt 100 ]; then
        after=$(( cur_light / 5 * 5 + 5 ))
        set_brightness "$after"
    fi
    notify_user
}

dec_brightness() {
    cur_light=$(get_brightness)
    after=$(( cur_light / 5 * 5 - 5 ))
    after=$(( after > 0 ? after : 1 ))
    set_brightness "$after"
    notify_user
}

black_out() {
    brightnessctl set 0%
}

case $1 in
    "--get") get_brightness ;;
    "--set") set_brightness "$2" ;;
    "--inc") inc_brightness ;;
    "--dec") dec_brightness ;;
    "--black-out") black_out ;;
esac

eww update brightness="$(get_brightness)"
