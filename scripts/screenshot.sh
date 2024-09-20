#!/usr/bin/env sh

icon_dir="$HOME/.config/mako/icons"

time=$(date +%Y-%m-%d-%H-%M-%S)
dir="$HOME/Pictures/Screenshots"
file="screenshot_${time}.png"

if [ ! -d "$dir" ]; then
	mkdir -p "$dir"
fi

if [ "$2" = "--no-save" ]; then
    dir=""
    file=""
fi

notify_view() {
    notify_cmd_shot="notify-send -h string:x-canonical-private-synchronous:shot-notify -u low -i $dir/$file"
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
    region=$(slurp -b 1B1F28CC )
    if [ -z "$region" ]; then
        return 0
    fi
    grim -g "$region" - | tee "$dir/$file" | wl-copy
}

case $1 in
    --now) shot_now ;;
    --in5) shot_5 ;;
    --win) shot_win ;;
    --area) shot_area ;;
esac

notify_view
