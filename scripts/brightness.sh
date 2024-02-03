#!/usr/bin/sh

get_brightness() {
    decimal=$(light)
    cur_light=${decimal%%.*}
	echo "${cur_light}"
}

notify_user() {
    if [ "$(eww get show_light_slider)" = "false" ]; then
        eww update show_light_slider=true
    fi
    pgrep brightness.sh | grep -v $$ | xargs kill
    sleep 2 && eww update show_light_slider=false &
}

set_brightness() {
    light -S "$2"
    notify_user
}

inc_brightness() {
    cur_light=$(get_brightness)
    if [ "$cur_light" -le 100 ]; then
        after=$(( cur_light / 5 * 5 + 5 ))
        light -S $after
    fi
    notify_user
}

dec_brightness() {
    cur_light=$(get_brightness)
    after=$(( cur_light / 5 * 5 - 5 ))
    after=$(( after > 0 ? after : 1 ))
    light -S $after &&
        notify_user
}

black_out() {
    light -S 0
}

case $1 in
    "--get") get_brightness ;;
    "--set") set_brightness "$@" ;;
    "--inc") inc_brightness ;;
    "--dec") dec_brightness ;;
    "--black-out") black_out ;;
esac

eww update brightness="$(get_brightness)"
