#!/usr/bin/env sh

PIN_FILE="$HOME/.config/cliphist/pinned.txt"
mkdir -p "$(dirname "$PIN_FILE")"
touch "$PIN_FILE"
PAGE_SIZE=8

close() {
    hyprctl dispatch 'hl.dsp.submap("reset")'
    eww update show_clipboard=false
    eww close clipboard
}

# Compact JSON object ({"text":...,"pinned":...}) at the given clip_json index, or empty.
entry_at() {
    eww get clip_json | jq -c ".[$1] // empty"
}

# Slice clip_all_json into the current clip_page, clamping page to range.
paginate() {
    all=$(eww get clip_all_json)
    total=$(printf '%s' "$all" | jq 'length')
    pages=$(( (total + PAGE_SIZE - 1) / PAGE_SIZE ))
    [ "$pages" -eq 0 ] && pages=1
    page=$(eww get clip_page)
    [ "$page" -lt 0 ] && page=$((pages - 1))
    [ "$page" -ge "$pages" ] && page=0
    slice=$(printf '%s' "$all" | jq -c --argjson p "$page" --argjson n "$PAGE_SIZE" '.[($p*$n):(($p+1)*$n)]')
    eww update clip_page="$page" clip_total_pages="$pages" clip_json="$slice" selected_clip_index=0
}

search_and_paginate() {
    eww update clip_all_json="$(clipboard.sh raw-list "$1")" clip_page=0
    paginate
}

case $1 in
    open)
        pos=$(hyprctl cursorpos)
        gx=$(printf '%s' "$pos" | cut -d, -f1 | tr -d ' ')
        gy=$(printf '%s' "$pos" | cut -d, -f2 | tr -d ' ')

        mon_name=$(hyprctl monitors -j | jq -r --argjson x "$gx" --argjson y "$gy" \
            '.[] | select(.x <= $x and $x < .x + .width and .y <= $y and $y < .y + .height) | .name')
        mon_xy=$(hyprctl monitors -j | jq -r --arg name "$mon_name" '.[] | select(.name == $name) | "\(.x) \(.y)"')
        mon_x=$(printf '%s' "$mon_xy" | cut -d' ' -f1)
        mon_y=$(printf '%s' "$mon_xy" | cut -d' ' -f2)
        lx=$((gx - mon_x))
        ly=$((gy - mon_y))

        eww update show_clipboard=true
        hyprctl dispatch 'hl.dsp.submap("clipboard")'

        search_and_paginate ""
        eww open clipboard --screen "$mon_name" --pos "${lx}x${ly}" --anchor "top left"
        ;;
    close) close ;;
    search)
        search_and_paginate "$2"
        ;;
    next)
        length=$(eww get clip_json | jq 'length')
        index=$(eww get selected_clip_index)
        if [ "$length" -eq 0 ]; then
            exit 0
        elif [ "$((index + 1))" -lt "$length" ]; then
            eww update selected_clip_index=$((index + 1))
        else
            page=$(eww get clip_page)
            eww update clip_page=$((page + 1))
            paginate
        fi
        ;;
    previous)
        length=$(eww get clip_json | jq 'length')
        index=$(eww get selected_clip_index)
        if [ "$length" -eq 0 ]; then
            exit 0
        elif [ "$index" -gt 0 ]; then
            eww update selected_clip_index=$((index - 1))
        else
            page=$(eww get clip_page)
            eww update clip_page=$((page - 1))
            paginate
            new_length=$(eww get clip_json | jq 'length')
            [ "$new_length" -gt 0 ] && eww update selected_clip_index=$((new_length - 1))
        fi
        ;;
    next-page)
        page=$(eww get clip_page)
        eww update clip_page=$((page + 1))
        paginate
        ;;
    previous-page)
        page=$(eww get clip_page)
        eww update clip_page=$((page - 1))
        paginate
        ;;
    raw-list)
        pinned=$(jq -R -c 'select(length > 0) | {text: ., pinned: true}' "$PIN_FILE")
        history_raw=$(cliphist list | cut -f2-)
        if [ -s "$PIN_FILE" ]; then
            history_raw=$(printf '%s\n' "$history_raw" | grep -vxFf "$PIN_FILE")
        fi
        if [ -n "$2" ]; then
            history_raw=$(printf '%s\n' "$history_raw" | fzf -f "$2")
        fi
        history=$(printf '%s\n' "$history_raw" | jq -R -c 'select(length > 0) | {text: ., pinned: false}')
        printf '%s\n%s\n' "$pinned" "$history" | sed '/^$/d' | jq -s -c '.'
        ;;
    select)
        if [ -n "$2" ]; then
            obj="$2"
        else
            obj=$(entry_at "$(eww get selected_clip_index)")
        fi
        close
        [ -z "$obj" ] && exit 0
        text=$(printf '%s' "$obj" | jq -r '.text')
        pinned=$(printf '%s' "$obj" | jq -r '.pinned')
        if [ "$pinned" = "true" ]; then
            printf '%s' "$text" | wl-copy
        else
            line=$(cliphist list | grep -F -- "	$text" | head -1)
            [ -n "$line" ] && printf '%s' "$line" | cliphist decode | wl-copy
        fi
        wtype -s 60 -M ctrl -k v -m ctrl
        ;;
    toggle-pin)
        if [ -n "$2" ]; then
            obj="$2"
        else
            obj=$(entry_at "$(eww get selected_clip_index)")
        fi
        [ -z "$obj" ] && exit 0
        text=$(printf '%s' "$obj" | jq -r '.text')
        if grep -qxF "$text" "$PIN_FILE"; then
            grep -vxF "$text" "$PIN_FILE" > "$PIN_FILE.tmp"
            mv "$PIN_FILE.tmp" "$PIN_FILE"
        else
            printf '%s\n' "$text" >> "$PIN_FILE"
        fi
        eww update clip_all_json="$(clipboard.sh raw-list)"
        paginate
        ;;
esac
