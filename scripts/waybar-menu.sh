#!/bin/sh

if [ "$(pidof rofi)" ]; then
    echo '                                                                           '
    pkill -RTMIN+5 waybar
else
    echo ' '
fi
