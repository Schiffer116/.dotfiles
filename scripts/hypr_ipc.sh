#!/usr/bin/env sh

socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR"/hypr/"$HYPRLAND_INSTANCE_SIGNATURE"/.socket2.sock | while read -r line; do
    case $line in
        'workspace>>'*)
            monitors=$(eww get monitors)
            current_monitor=$(hyprctl activeworkspace -j | jq -r '.monitor')
            previous_workspace=$(echo "$monitors" | jq ".[] | select(.name == \"${current_monitor}\") | .currentWorkspace")
            current_workspace=$(echo "$line" | awk -F '>>' '{ print $2 }')
            # next_wallpaper="$(find ~/Pictures/arts/ | shuf -n 1)"
            # hyprctl hyprpaper wallpaper "$current_monitor,$next_wallpaper"
            eww update monitors="$(echo "$monitors" | jq "map(
                if .name == \"$current_monitor\" then
                    .previousWorkspace = $previous_workspace |
                    .currentWorkspace = $current_workspace
                else
                    .
                end
                )")"
            ;;

        'activewindow>>'*)
            active_window="$(echo "$line" | awk -F '>>' '{
                gsub(",", ", ", $2);
                sub(/\\n.*/, "", $2);
                sub(/^, $/, "", $2);
                print $2
            }')"
            if [ "$active_window" != ',' ]; then
                eww update cur_win="$active_window"
            else
                eww update cur_win=''
            fi
            ;;
    esac
done
