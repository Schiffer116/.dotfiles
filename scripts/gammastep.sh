#!/usr/bin/env sh

get_temp() {
    eww get color_temp
}

set_temp() {
    pkill gammastep
    gammastep -O $(( 6500 - $1 + 1000 ))
    eww update color_temp="$1"
    notify_user
}

notify_user() {
    eww update show_temp_slider=true
    sleep 2
    if ! pgrep -f "$0" | grep -v $$; then
        eww update show_temp_slider=false
    fi
}

increase_temp() {
    cur_temmp=$(get_brightness)
    if [ "$cur_temmp" -lt 6500 ]; then
        after=$(( cur_temmp / 5 * 5 + 5 ))
        set_brightness "$after"
    fi
}

