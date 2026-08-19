#!/usr/bin/env sh

close() {
    hyprctl dispatch 'hl.dsp.submap("reset")'
    eww close laptop_powermenu
    eww close eq270q_powermenu
}

case $1 in
    open)
        eww update active_button=0
        eww open powermenu --screen 0 --id laptop_powermenu
        eww open powermenu --screen 1 --id eq270q_powermenu
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

