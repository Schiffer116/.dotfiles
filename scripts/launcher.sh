#!/usr/bin/env sh

APP_DIR='/usr/share/applications/'
PAGE_SIZE=10

close() {
    hyprctl dispatch 'hl.dsp.submap("reset")'
    eww update show_launcher=false
    eww close launcher
}

# Slice app_all_json into the current app_page, clamping page to range.
paginate() {
    all=$(eww get app_all_json)
    total=$(printf '%s' "$all" | jq 'length')
    pages=$(( (total + PAGE_SIZE - 1) / PAGE_SIZE ))
    [ "$pages" -eq 0 ] && pages=1
    page=$(eww get app_page)
    [ "$page" -lt 0 ] && page=$((pages - 1))
    [ "$page" -ge "$pages" ] && page=0
    slice=$(printf '%s' "$all" | jq -c --argjson p "$page" --argjson n "$PAGE_SIZE" '.[($p*$n):(($p+1)*$n)]')
    eww update app_page="$page" app_total_pages="$pages" app_json="$slice" selected_app_index=0
}

search_and_paginate() {
    eww update app_all_json="$(launcher.sh fuzzy "$1")" app_page=0
    paginate
}

case $1 in
    open)
        eww update show_launcher=true
        hyprctl dispatch 'hl.dsp.submap("launcher")'

        search_and_paginate ""
        eww open launcher
        ;;
    close) close ;;
    search)
        search_and_paginate "$2"
        ;;
    next)
        length=$(eww get app_json | jq 'length')
        index=$(eww get selected_app_index)
        if [ "$length" -eq 0 ]; then
            exit 0
        elif [ "$((index + 1))" -lt "$length" ]; then
            eww update selected_app_index=$((index + 1))
        else
            page=$(eww get app_page)
            eww update app_page=$((page + 1))
            paginate
        fi
        ;;
    previous)
        length=$(eww get app_json | jq 'length')
        index=$(eww get selected_app_index)
        if [ "$length" -eq 0 ]; then
            exit 0
        elif [ "$index" -gt 0 ]; then
            eww update selected_app_index=$((index - 1))
        else
            page=$(eww get app_page)
            eww update app_page=$((page - 1))
            paginate
            new_length=$(eww get app_json | jq 'length')
            [ "$new_length" -gt 0 ] && eww update selected_app_index=$((new_length - 1))
        fi
        ;;
    next-page)
        page=$(eww get app_page)
        eww update app_page=$((page + 1))
        paginate
        ;;
    previous-page)
        page=$(eww get app_page)
        eww update app_page=$((page - 1))
        paginate
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
