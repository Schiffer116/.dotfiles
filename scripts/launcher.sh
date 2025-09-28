#!/usr/bin/env sh

APP_DIR='/usr/share/applications/'

close() {
    hyprctl dispatch submap reset
    eww update show_launcher=false
    sleep 0.3
    eww close launcher
}

case $1 in
    open)
        eww update show_launcher=true
        hyprctl dispatch submap launcher

        eww update app_json="$(launcher.sh fuzzy)" selected_app_index=0
        eww open launcher
        ;;
    close) close ;;
    next)
        length=$(eww get app_json | jq 'length')
        index=$(eww get selected_app_index)
        eww update selected_app_index=$(( ( index + 1 ) % length ))
        ;;
    previous)
        length=$(eww get app_json | jq 'length')
        index=$(eww get selected_app_index)
        eww update selected_app_index=$(( (length + index - 1) % length ))
        ;;
    fuzzy)
        awk -F= '
            /^\[Desktop/ {
                if (name && gui) print name
                name=""; gui=1
            }
            /^Name=/ { name = $2 }
            /^Terminal=/ && $2=="true" { gui = 0 }
            END { if (name && gui) print name }
        ' $APP_DIR/* | sort -u | fzf -f "$2" | jq -Rc -s 'split("\n")[:-1]'
        eww update selected_app_index=0
        ;;
    launch)
        if [ -n "$2" ]; then
            launch_app="$2"
        else
            launch_app=$(eww get app_json | jq -r ".[$(eww get selected_app_index)]")
        fi

        command=$(
            rg --files-with-matches "^Name=$launch_app" $APP_DIR/* | \
            xargs rg --no-line-number "^Exec=" | head -1 | sed -E 's/^Exec=([^ ]+)( .+)?$/\1/'
        )

        close
        $command
        ;;
esac
