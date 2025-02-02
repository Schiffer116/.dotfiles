#!/usr/bin/env sh

playerctl metadata mpris:artUrl --follow | tail --bytes=+8 | while read -r line; do
    magick "$line" -colors 1 -define histogram:unique-colors=true -format "%c" histogram:info: # | \
    # grep -o '#[A-Z0-9]\{6\}'
done
