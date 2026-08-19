#!/usr/bin/env sh

get_monitor() {
    hyprctl activeworkspace -j | jq -r '.monitor'
}

get_brightness() {
    brightnessctl i --machine-readable | awk -F',' '{ sub("%", ""); print $4 }'
}

set_brightness() {
    sign=$1
    amount=$2
    monitor="$(get_monitor)"
    case "$monitor" in
        eDP-1)
            if [ "$sign" = "+" ]; then
                brightnessctl set "$sign$amount%"
            elif [ "$sign" = "-" ]; then
                echo "$amount%$sign"
                brightnessctl set "$amount%$sign" --min-value=1
            fi
            ;;
        HDMI-A-1)
            ddcutil setvcp 10 "$sign" "$amount"
            ;;
    esac
    eww update brightness="$(get_brightness)"
}

case $1 in
    get) get_brightness ;;
    set) set_brightness "$2" ;;
    increase) set_brightness + 1 ;;
    decrease) set_brightness - 1;;
    # blackout) brightnessctl set 0% ;;
esac
