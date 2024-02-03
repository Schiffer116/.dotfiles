#!/bin/sh

close() {
    hyprctl dispatch submap reset
    eww close powermenu
}

case $1 in
    "--open")
        eww update active_button=0
        eww open powermenu
        hyprctl dispatch submap powermenu ;;
    "--close")
        close ;;
    "--next" | "--previous") 
        active_button=$(eww get active_button)
        case $1 in
            "--next") new_active=$(( (active_button + 1) % 4 ));;
            "--previous") new_active=$(( (active_button + 3) % 4 ));;
        esac
        eww update active_button="$new_active" ;;
    "--action")
        case $2 in
            0) systemctl poweroff ;;
            1) systemctl reboot ;;
            2) 
                close
                systemctl suspend
                wpctl set-mute @DEFAULT_AUDIO_SINK@ 1
                ;;
            3) 
                close
                swaylock.sh ;;
        esac ;;
esac

