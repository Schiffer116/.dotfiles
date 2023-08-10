#!/bin/sh


get_lang() {
    cur_lang="$(ibus engine)"
    if [ "$cur_lang" = "BambooUs" ]; then
        echo E
    else
        echo V
    fi
}


cycle_lang() {
    if [ "$(get_lang)" = "E" ]; then
        ibus engine Bamboo
    elif [ "$(get_lang)" = "V" ]; then
        ibus engine BambooUs
    fi
}


if [ "$1" = "--get" ]; then
    get_lang
elif [ "$1" = "--next" ]; then
    cycle_lang
    pkill -RTMIN+4 waybar
fi
