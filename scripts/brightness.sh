#!/usr/bin/env sh

SOCKET=$BRIGHTNESS_SERVER_SOCKET

# Sends one step byte per percent to the daemon, which batches and applies them.
# Usage: send_steps <+|-> [percent, default 1]
send_steps() {
    case ${2:-1} in
        ''|*[!0-9]*) echo "delta must be a whole number of percent: $2" >&2; exit 1 ;;
    esac
    printf "%${2:-1}s" '' | tr ' ' "$1" | socat - UNIX-SENDTO:"$SOCKET"
}

get_brightness() {
    brightnessctl i --machine-readable | awk -F',' '{ sub("%", ""); print $4 }'
}

case $1 in
    get) get_brightness ;;
    increase) send_steps + "$2" ;;
    decrease) send_steps - "$2" ;;
    # blackout) brightnessctl set 0% ;;
esac
