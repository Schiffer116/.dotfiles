#!/usr/bin/sh

iDIR="$HOME/.config/mako/icons"

get_brightness() {
    decimal=$(light)
    cur_light=${decimal%%.*}
	echo "${cur_light}"
}

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
    after=$(( after > 0 ? after : 1 ))
    light -S $after &&
        notify_user
}

black_out() {
    light -S 0
}

if [ "$1" = "--get" ]; then
    get_brightness
elif [ "$1" = "--inc" ]; then
	inc_brightness
elif [ "$1" = "--dec" ]; then
	dec_brightness
elif [ "$1" = "--black-out" ]; then
    black_out
fi
