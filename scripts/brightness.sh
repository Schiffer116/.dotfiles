#!/usr/bin/sh

iDIR="$HOME/.config/mako/icons"

get_icon() {
	current=$(get_brightness)
	if [ "$current" -le 20 ]; then
		echo "$iDIR/brightness-20.png"
	elif [ "$current" -le 40 ]; then
		echo "$iDIR/brightness-40.png"
	elif [ "$current" -le 60 ]; then
		echo "$iDIR/brightness-60.png"
	elif [ "$current" -le 80 ]; then
		echo "$iDIR/brightness-80.png"
	elif [ "$current" -le 100 ]; then
		echo "$iDIR/brightness-100.png"
	fi
}

notify_user() {
	notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -i "$(get_icon)" "Brightness" "Brightness at $(get_brightness)%"
}

get_brightness() {
    cur_light=$(light | cut -d. -f1)
	echo "${cur_light}"
}

inc_brightness() {
    cur_light=$(get_brightness)
    if [ "$cur_light" -le 100 ]; then
        after=$(( cur_light / 5 * 5 + 5 ))
        light -S $after
    fi
    notify_user
}

dec_brightness() {
    cur_light=$(get_brightness)
    after=$(( cur_light / 5 * 5 - 5 ))
    light -S $after &&
        notify_user
}

# Execute accordingly
if [ "$1" = "--inc" ]; then
	inc_brightness
elif [ "$1" = "--dec" ]; then
	dec_brightness
else
	get_brightness
fi
