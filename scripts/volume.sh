#!/bin/sh

iDIR="$HOME/.config/mako/icons"

get_volume() {
	volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | cut -d " " -f2 | tr -d '.' | sed 's/^0\{1,2\}//')
	echo "$volume"
}

set_volume() {
    wpctl set-volume @DEFAULT_AUDIO_SINK@ 0."$2"
}

get_icon() {
	current=$(get_volume)
	if [ "$current" -eq 0 ]; then
		echo "$iDIR/volume-mute.png"
	elif [ "$current" -le 30 ]; then
		echo "$iDIR/volume-low.png"
	elif [ "$current" -le 60 ]; then
		echo "$iDIR/volume-mid.png"
	elif [ "$current" -le 100 ]; then
		echo "$iDIR/volume-high.png"
	fi
}

notify_user() {
	notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -i "$(get_icon)" "Volume" "Volume at $(get_volume)%"
}

mutation() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -o MUTED
}

inc_volume() {
    if [ "$(mutation)" = "MUTED" ]; then
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
    if [ "$(mutation)" = "MUTED" ]; then
        toggle_mute
        return 0
    fi

    cur_volume="$(get_volume)"
    new_volume="$(( cur_volume / 5 * 5 - 5 ))"

    wpctl set-volume @DEFAULT_AUDIO_SINK@ "$new_volume%"
    notify_user
}

toggle_mute() {
    if [ "$(mutation)" = "MUTED" ]; then
        notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -i "$(get_icon)" "Volume" "Volume Unmuted"
        eww update muted=false
    else
        notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -i "$iDIR/volume-mute.png" "Volume" "Volume Muted"
        eww update muted=true
    fi
    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle 
}

# Toggle Mic
toggle_mic() {
	if [ "$(pamixer --source 66 --get-mute)" = "false" ]; then
		pamixer -m --source 66 && 
            notify-send -u low -i "$iDIR/microphone-mute.png" "Microphone Switched OFF"
	elif [ "$(pamixer --source 66 --get-mute)" = "true" ]; then
		pamixer -u --source 66 && 
            notify-send -u low -i "$iDIR/microphone.png" "Microphone Switched ON"
	fi
}

# Execute accordingly
case $1 in
    "--get") get_volume ;;
    "--get-mute") 
        if [ "$(mutation)" = "MUTED" ]; then
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
