#!/usr/bin/env sh

socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR"/hypr/"$HYPRLAND_INSTANCE_SIGNATURE"/.socket2.sock | while read -r line; do
    case $line in
        'workspace>>'*)
            old_ws=$(eww get ws_cur)
            new_ws=$(echo "$line" | awk -F '>>' '{ print $2 }')
            eww update ws_cur="$new_ws" ws_prv="$old_ws"
            ;;
        'activewindow>>'*)
            active_win="$(echo "$line" | awk -F '>>' '{ print $2 }' | sed -E -e 's/,/, /' -e 's/^, $//')"
            if [ "$active_win" != ',' ]; then
                eww update cur_win="$active_win"
            else
                eww update cur_win=''
            fi
            ;;
    esac
done
