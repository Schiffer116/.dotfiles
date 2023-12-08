#!/usr/bin/env bash

dir="$HOME/.config/rofi/powermenu/type-4"
theme='style-2'

uptime="$(uptime -p | sed -e 's/up //g')"

shutdown=''
reboot=''
lock=''
suspend=''

rofi_cmd() {
	rofi -dmenu \
		-p "Goodbye ${USER}" \
		-mesg "Uptime: $uptime" \
		-theme "${dir}"/${theme}.rasi
}

run_rofi() {
	echo -e "$lock\n$suspend\n$reboot\n$shutdown" | rofi_cmd
}

run_cmd() {
    if [[ $1 == '--shutdown' ]]; then
        systemctl poweroff
    elif [[ $1 == '--reboot' ]]; then
        systemctl reboot
    elif [[ $1 == '--suspend' ]]; then
        # hacky way to do this
        # brightness.sh --black-out
        amixer set Master mute
        systemctl suspend
        # swaylock.sh 
        # light -S 20
    elif [[ $1 == '--lock' ]]; then
        amixer set Master mute
        playerctl pause
        swaylock.sh
    fi
}

chosen="$(run_rofi)"
case ${chosen} in
    "$shutdown") run_cmd --shutdown ;;
    "$reboot") run_cmd --reboot ;;
    "$lock") run_cmd --lock ;;
    "$suspend") run_cmd --suspend ;;
esac
