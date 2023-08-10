#!/bin/sh

iDIR="$HOME/.config/mako/icons"

get_volume() {
	volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | cut -d " " -f2 | tr -d '.' | sed 's/^0//')
	echo "$volume"
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

is_mute() {
    pactl -- get-sink-mute @DEFAULT_SINK@ | cut -d ' ' -f2
}

inc_volume() {
    if [ "$(is_mute)" = "yes" ]; then
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
    if [ "$(is_mute)" = "yes" ]; then
        toggle_mute
        return 0
    fi

    cur_volume="$(get_volume)"
    new_volume="$(( cur_volume / 5 * 5 - 5 ))"

    wpctl set-volume @DEFAULT_AUDIO_SINK@ "$new_volume%"
    notify_user
}

toggle_mute() {
    if [ "$(is_mute)" = "no" ]; then
		pactl -- set-sink-mute @DEFAULT_SINK@ toggle &&
            notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -i "$iDIR/volume-mute.png" "Volume" "Volume Muted"
    elif [ "$(is_mute)" = "yes" ]; then
        pactl -- set-sink-mute @DEFAULT_SINK@ toggle &&
            notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -i "$(get_icon)" "Volume" "Volume Unmuted"
	fi
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
if [ "$1" = "--get" ]; then
	get_volume
elif [ "$1" = "--inc" ]; then
	inc_volume
elif [ "$1" = "--dec" ]; then
	dec_volume
elif [ "$1" = "--toggle" ]; then
	toggle_mute
elif [ "$1" = "--toggle-mic" ]; then
	toggle_mic
fi
