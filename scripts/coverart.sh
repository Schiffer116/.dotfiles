#!/bin/sh

cur_song=""
while true; do
    if [ "$cur_song" = "$(playerctl -p spotify metadata title)" ]; then
        sleep 2
    else 
        cur_song="$(playerctl -p spotify metadata title)"
        curl -s -L "$(playerctl -p spotify metadata mpris:artUrl)" > /tmp/cover-art
        echo /tmp/cover-art
    fi
done
