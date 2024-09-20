#!/usr/bin/env sh

get_volume() {
	volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | cut -d " " -f2 | tr -d '.' | sed 's/^0\{1,2\}//')
	echo "$volume"
}

set_volume() {
    wpctl set-volume @DEFAULT_AUDIO_SINK@ "$1%"
    eww update volume="$(get_volume)"
    notify_user
}

notify_user() {
    eww update show_sound_slider=true
    sleep 2
    if ! pgrep -f "$0" | grep -v $$; then
        eww update show_sound_slider=false
    fi
}

is_muted() {
    muted=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -o MUTED)
    if [ "$muted" = "MUTED" ]; then
        echo true
    else
        echo false
    fi
}

inc_volume() {
    if [ "$(is_muted)" = "true" ]; then
        toggle_mute
    fi
    cur_volume="$(get_volume)"
    new_volume="$(( cur_volume / 5 * 5 + 5 ))"
    if [ "$new_volume" -gt 100 ]; then
        new_volume=100
    fi
    set_volume $new_volume
}

dec_volume() {
    if [ "$(is_muted)" = "true" ]; then
        toggle_mute
    fi
    cur_volume="$(get_volume)"
    new_volume="$(( cur_volume / 5 * 5 - 5 ))"
    set_volume $new_volume
}

toggle_mute() {
    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    eww update muted="$(is_muted)"
}

mute() {
    wpctl set-mute @DEFAULT_AUDIO_SINK@ 1
    eww update muted="$(is_muted)"
}


case $1 in
    --get) get_volume ;;
    --get-mute) is_muted ;;
    --set) set_volume "$2" ;;
    --inc) inc_volume ;;
    --dec) dec_volume ;;
    --toggle) toggle_mute ;;
    mute) mute ;;
esac
