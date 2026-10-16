#!/usr/bin/env sh

SOCKET=$VOLUME_SERVER_SOCKET

# Sends one step byte per percent to the daemon, which batches and applies them.
# Usage: send_steps <+|-> [percent, default 1]
send_steps() {
    case ${2:-1} in
        ''|*[!0-9]*) echo "delta must be a whole number of percent: $2" >&2; exit 1 ;;
    esac
    printf "%${2:-1}s" '' | tr ' ' "$1" | socat - UNIX-SENDTO:"$SOCKET"
}

get_volume() {
    wpctl get-volume @DEFAULT_SINK@ | awk '{ gsub(/[^0-9]/, ""); print $1 + 0 }'
}

is_muted() {
    wpctl get-volume @DEFAULT_SINK@ | tail -n 1 | grep -q '\[MUTED\]' && printf true || printf false
}

toggle_mute() {
    wpctl set-mute @DEFAULT_SINK@ "$1"
    eww update volume="$(get_volume)"
    eww update muted="$(is_muted)"
}

case $1 in
    get) get_volume ;;
    increase) send_steps + "$2" ;;
    decrease) send_steps - "$2" ;;
    is-muted) is_muted ;;
    toggle-mute) toggle_mute toggle ;;
    mute) toggle_mute 1 ;;
esac
