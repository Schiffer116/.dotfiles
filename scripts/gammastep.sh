#!/usr/bin/env sh

get_temp() {
    eww get color_temp
}

set_temp() {
    pkill gammastep
    gammastep -O "$1"
    eww update color_temp="$1"
    notify_user
}

decrease_temp() {
    cur_temmp=$(get_temp)
    if [ "$cur_temmp" -lt 6500 ]; then
        after=$(( cur_temmp - 100))
        set_temp "$after"
    fi
}

increase_temp() {
    cur_temmp=$(get_temp)
    if [ "$cur_temmp" -gt 1000 ]; then
        after=$(( cur_temmp + 100))
        set_temp "$after"
    fi
}

case $1 in
    get) get_tegmp ;;
    set) set_temp "$2" ;;
    increase) increase_temp ;;
    decrease) decrease_temp ;;
esac
