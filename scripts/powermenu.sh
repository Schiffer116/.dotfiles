#!/usr/bin/env sh

# One powermenu window per enabled output, with id powermenu_<output>.
close() {
    hyprctl dispatch 'hl.dsp.submap("reset")'
    eww active-windows | cut -d: -f1 | grep '^powermenu_' | xargs -r eww close
}

case $1 in
    open)
        eww update active_button=0
        for output in $(hyprctl monitors -j | jq -r '.[].name'); do
            eww --no-daemonize open powermenu --screen "$output" --id "powermenu_$output"
        done
        hyprctl dispatch 'hl.dsp.submap("powermenu")'
        ;;
    close)
        close
        ;;
    next | previous)
        active_button=$(eww get active_button)
        case $1 in
            next) new_active=$(( (active_button + 1) % 4 ));;
            previous) new_active=$(( (active_button + 3) % 4 ));;
        esac
        eww update active_button="$new_active"
        ;;
    action)
        action=$2
        if [ -z "$action" ]; then
            action=$(eww get active_button)
        fi

        case $action in
            0)
                systemctl poweroff
                ;;
            1)
                systemctl reboot
                ;;
            2)
                close
                volume.sh mute
                playerctl pause
                systemctl suspend
                ;;
            3)
                close
                swaylock.sh
                ;;
        esac
        ;;
esac

