#!/usr/bin/env sh

app_dir='/usr/share/applications/'

open() {
    hyprctl dispatch submap launcher
    eww update app_json="$(launcher.sh fuzzy)" selected_app_index=0
    eww open launcher
}

close() {
    hyprctl dispatch submap reset
    eww close launcher
}

all_apps() {
    rg --no-filename --no-line-number "^Name=" $app_dir/* | \
    sort | uniq | sed -Ee 's/^Name=//'
}

to_json() {
    jq -R -s 'split("\n")[:-1]'
}

case $1 in
    open) open ;;
    close) close ;;
    next)
        length=$(eww get app_json | jq 'length')
        index=$(eww get selected_app_index)
        if [ "$index" = "$(( length - 1 ))" ]; then
            eww update selected_app_index=0
        else
            eww update selected_app_index=$(( index + 1 ))
        fi
        ;;
    previous)
        index=$(eww get selected_app_index)
        if [ "$index" = 0 ]; then
            length=$(eww get app_json | jq 'length')
        else
            eww update selected_app_index=$(( index - 1 ))
        fi
        ;;
    fuzzy)
        all_apps | fzf -f "$2" | to_json

        length=$(eww get app_json | jq 'length')
        index=$(eww get selected_app_index)
        if [ "$index" -ge "$length" ]; then
            eww update selected_app_index=$(( length - 1 ))
        fi
        ;;
    launch)
        clicked=$2
        if [ -n "$clicked" ]; then
            launch_app=$clicked
        else
            launch_app=$(eww get app_json | jq -r ".[$(eww get selected_app_index)]")
        fi

        command=$(
            rg --files-with-matches "^Name=$launch_app" $app_dir/* | \
            xargs rg --no-line-number "^Exec=" | head -1 | sed -E 's/^Exec=([^ ]+)( .+)?$/\1/'
        )
        close
        $command
        ;;
esac
