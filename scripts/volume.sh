#!/usr/bin/env sh

get_volume() {
    wpctl get-volume @DEFAULT_SINK@ | awk '{ gsub(/[^0-9]/, ""); print $1 + 0 }'
}

set_volume() {
    echo "set $1" > /tmp/volume.pipe
}

is_muted() {
    wpctl get-volume @DEFAULT_SINK@ | grep -q '\[MUTED\]' && printf true || printf false
}

toggle_mute() {
    wpctl set-mute @DEFAULT_SINK@ "$1"
    eww update volume="$(get_volume)"
    eww update muted="$(is_muted)"
}

case $1 in
    get) get_volume ;;
    set) set_volume "$2";;
    increase) set_volume 1%+ ;;
    decrease) set_volume 1%- ;;
    is-muted) is_muted ;;
    toggle-mute) toggle_mute toggle ;;
    mute) toggle_mute 1 ;;
esac
