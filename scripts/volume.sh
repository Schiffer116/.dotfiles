#!/bin/sh

iDIR="$HOME/.config/mako/icons"

get_volume() {
	volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | cut -d " " -f2 | tr -d '.' | sed 's/^0\{1,2\}//')
	echo "$volume"
}

set_volume() {
    wpctl set-volume @DEFAULT_AUDIO_SINK@ 0."$2"
}

notify_user() {
    if [ "$(eww get show_sound_slider)" = "false" ]; then
        eww update show_sound_slider=true
    fi
    pgrep volume.sh | grep -v $$ | xargs kill
    sleep 2 && eww update show_sound_slider=false &
}

muted() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -o MUTED
}

inc_volume() {
    if [ "$(muted)" = "MUTED" ]; then
        toggle_mute
        return 0
    fi
    
    cur_volume="$(get_volume)"
    new_volume="$(( cur_volume / 5 * 5 + 5 ))"
    if [ "$new_volume" -gt 100 ]; then
        new_volume=100
    fi

    wpctl set-volume @DEFAULT_AUDIO_SINK@ "$new_volume%"
    notify_user
}

dec_volume() {
    if [ "$(muted)" = "MUTED" ]; then
        toggle_mute
        return 0
    fi

    cur_volume="$(get_volume)"
    new_volume="$(( cur_volume / 5 * 5 - 5 ))"

    wpctl set-volume @DEFAULT_AUDIO_SINK@ "$new_volume%"
    notify_user
}

toggle_mute() {
    if [ "$(muted)" = "MUTED" ]; then
        eww update muted=false
    else
        eww update muted=true
    fi
    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle 
    notify_user
}

toggle_mic() {
	if [ "$(pamixer --source 66 --get-mute)" = "false" ]; then
		pamixer -m --source 66 
	elif [ "$(pamixer --source 66 --get-mute)" = "true" ]; then
		pamixer -u --source 66
	fi
}

# Execute accordingly
case $1 in
    "--get") get_volume ;;
    "--get-mute") 
        if [ "$(muted)" = "MUTED" ]; then
            echo true
        else 
            echo false
        fi
        ;;
    "--set") set_volume "$@" ;;
    "--inc") inc_volume ;;
    "--dec") dec_volume ;;
    "--toggle") toggle_mute ;;
    "--toggle-mic") toggle_mic ;;
esac

eww update volume="$(get_volume)"
