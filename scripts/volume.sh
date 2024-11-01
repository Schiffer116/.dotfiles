#!/usr/bin/env sh

get_volume() {
	wpctl get-volume @DEFAULT_SINK@ | sed -E 's/[^0-9]//g'
}

notify_user() {
    eww update show_sound_slider=true
    sleep 2
    if ! pgrep -f "$0" | grep -v $$; then
        eww update show_sound_slider=false
    fi
}

set_volume() {
    toggle_mute 0
    wpctl set-volume @DEFAULT_SINK@ "$1" --limit=1.0
    eww update volume="$(get_volume)"
    notify_user
}

is_muted() {
    wpctl get-volume @DEFAULT_SINK@ | sed -Ee 's/.*]$/true/' -e 's/.*[0-9]$/false/'
}

toggle_mute() {
    wpctl set-mute @DEFAULT_AUDIO_SINK@ "$1"
    eww update muted="$(is_muted)"
}

case $1 in
    get) get_volume ;;
    set) set_volume "$2%" ;;
    inc) set_volume 5%+ ;;
    dec) set_volume 5%- ;;
    is-muted) is_muted ;;
    toggle) toggle_mute toggle ;;
    mute) toggle_mute 1 ;;
esac
