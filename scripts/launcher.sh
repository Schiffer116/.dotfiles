#!/usr/bin/env sh

open() {
    hyprctl dispatch submap launcher &
}

close() {
    hyprctl dispatch submap reset &
    refresh_app
}

refresh_app() {
    eww set app_json="$(all_apps | to_json)"
}

all_apps() {
    # grep -EL '^(Terminal=true|NoDisplay=true)' /nix/store/*/share/applications/*.desktop | \
    grep -EL '^(Terminal=true|NoDisplay=true)' /run/current-system/sw/share/applications | \
        xargs grep -h '^Name=' | \
        sed -Ee 's/^Name=//' | \
        sort | uniq
}

to_json() {
    printf '[%s]' "$(sed 's/^\|$/"/g')" | tr '\n' ','
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
            eww update selected_app_index=$(( length - 1))
        else
            eww update selected_app_index=$(( index - 1 ))
        fi
        ;;
    fuzzy) all_apps | fzf -f "$2" | to_json;;
    launch)
        clicked=$2
        if [ -z "$clicked" ]; then
            apps_json=$(eww get app_json)
            app_index=$(eww get selected_app_index)
            launch_app=$(
                echo "$apps_json" | \
                jq ".[$app_index]" | \
                tr -d '"'
            )
        else
            launch_app=$clicked
        fi

        command=$(
            grep -l "^Name=$launch_app" /nix/store/*/share/applications/*.desktop | \
            xargs grep -hm 1 "^Exec=" | sed -e 's/^Exec=//' -Ee 's/ .+//' | sort | uniq
        )
        close &
        $command
        ;;
esac
