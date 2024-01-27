#!/bin/sh

if [ "$(pidof rofi)" ]; then
    pkill -RTMIN+5 waybar
fi
