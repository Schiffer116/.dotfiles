#!/usr/bin/env sh

icon_dir="$HOME/.config/mako/icons"

time=$(date +%Y-%m-%d-%H-%M-%S)
dir="Pictures/Screenshots"
file="screenshot_${time}.png"

if [ ! -d "$dir" ]; then
	mkdir -p "$dir"
fi

if [ "$2" = "--no-save" ]; then
    dir=""
    file=""
fi

notify_view() {
    notify_cmd_shot="notify-send -h string:x-canonical-private-synchronous:shot-notify -u low -i ${icon_dir}/picture.png"
	${notify_cmd_shot} "Copied to clipboard."
	if [ -e "$dir/$file" ]; then
		${notify_cmd_shot} "Screenshot Saved."
	else
		${notify_cmd_shot} "Screenshot Deleted."
	fi
}

countdown() {
	for sec in $(seq "$1" -1 1); do
		notify-send -h string:x-canonical-private-synchronous:shot-notify -t 1000 -i "$icon_dir"/timer.png "Taking shot in : $sec"
		sleep 1
	done
}

shot_now() {
	grim - | tee "$dir/$file" | wl-copy
}

shot_5() {
	countdown '5'
	sleep 1 && grim - | tee "$dir/$file" | wl-copy
}

shot_win() {
	w_pos=$(hyprctl activewindow | grep 'at:' | cut -d':' -f2 | tr -d ' ' | tail -n1)
	w_size=$(hyprctl activewindow | grep 'size:' | cut -d':' -f2 | tr -d ' ' | tail -n1 | sed s/,/x/g)
	grim -g "$w_pos $w_size" - | tee "$dir/$file" | wl-copy
}

shot_area() {
    grim -g "$(slurp -b 1B1F28CC )" - | tee "$dir/$file" | wl-copy
}

if [ "$1" = "--now" ]; then
	shot_now
elif [ "$1" = "--in5" ]; then
	shot_5
elif [ "$1" = "--win" ]; then
	shot_win
elif [ "$1" = "--area" ]; then
	shot_area
else
	echo "Available Options : --now --in5 --in10 --win --area" 1>&2
fi

notify_view
