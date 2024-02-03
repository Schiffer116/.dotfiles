#!/bin/sh

case $1 in
    "--open")
        eww update selected_app_index=0 &
        eww open launcher &
        hyprctl dispatch submap launcher
        ;;
    "--close")
        hyprctl dispatch submap reset &
        eww close launcher
        ;;
    "--next")
        length=$(eww get app_json | jq 'length')
        index=$(eww get selected_app_index)
        if [ "$index" = "$length" ]; then
            eww update selected_app_index=0
        else 
            eww update selected_app_index=$(( index + 1 ))
        fi
        ;;
    "--previous")
        index=$(eww get selected_app_index)
        if [ "$index" = 0 ]; then
            length=$(eww get app_json | jq 'length')
            eww update selected_app_index=$(( length - 1))
        else 
            eww update selected_app_index=$(( index - 1 ))
        fi
        ;;
    "--fuzzy")
        app_names=$(
            grep -EL '^(Terminal=true|NoDisplay=true)' /usr/share/applications/* | \
            xargs grep -h '^Name=' | sed -Ee 's/^Name=/"/' -e 's/$/"/' | fzf -f "$2"
        )
        content=$(echo $app_names | sed 's/" "/","/g')
        json=$(printf "[%s]" "$content")
        echo "$json"
        ;;
    "--launch")
        if [ -z "$2" ]; then
            apps_json=$(eww get app_json) 
            app_index=$(eww get selected_app_index)
            launch_app=$(
                echo "$apps_json" | \
                jq ".[$app_index]" | \
                tr -d '"'
            )
        else
            launch_app=$2
        fi

        command=$(
            grep -l "^Name=$launch_app" /usr/share/applications/* | \
            xargs grep -hm 1 "^Exec=" | \
            sed -e 's/^Exec=//' -Ee 's/ .+//'
        )
        hyprctl dispatch submap reset &
        eww close launcher &
        $command
        ;;
esac
