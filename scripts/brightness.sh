#!/usr/bin/sh

get_backlight() {
    LIGHT=$(light | cut -d. -f1)
	echo "${LIGHT}"
}

inc_backlight() {
    curLight=$(get_backlight);
    after=$(( curLight / 5 * 5 + 5 ));
    light -S $after;
}

dec_backlight() {
    curLight=$(get_backlight);
    after=$(( curLight - 5 ));
    light -S $after;
}

# Execute accordingly
if [ "$1" = "--inc" ]; then
	inc_backlight
elif [ "$1" = "--dec" ]; then
	dec_backlight
else
	get_backlight
fi
