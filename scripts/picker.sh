#!/usr/bin/env bash
# shellcheck disable=SC2016 # $names inside single quotes are jq variables
# One keyboard picker for every list: apps (SUPER+D) and clipboard history (SUPER+V).
#
#   picker.sh launcher|clipboard      open that picker on the focused output
#   picker.sh search QUERY | next | previous | next-page | previous-page
#   picker.sh select [N]              pick the selected entry, or entry N of the page
#   picker.sh toggle-pin              clipboard only: keep the entry at the top
#   picker.sh close
#
# The open picker's state lives in $XDG_RUNTIME_DIR/picker.json. Paging and selection are pure jq
# functions in picker.jq (tested by picker.test.sh); eww only renders the `picker` variable.
# Each list is an adapter below: <name>_list QUERY prints its entries, <name>_select ENTRY acts.
# (fzf -f exits 1 when nothing matches; under pipefail that must not abort the picker.)
set -euo pipefail

here=$(dirname "$(readlink -f "$0")")
state=${PICKER_STATE:-$XDG_RUNTIME_DIR/picker.json}
app_dir=${PICKER_APP_DIR:-/usr/share/applications}
pin_file=${PICKER_PIN_FILE:-$HOME/.config/cliphist/pinned.txt}

# jq with picker.jq loaded: pj [jq options...] FILTER FILE
pj() {
    local args=("${@:1:$#-2}") filter=${*: -2:1} file=${*: -1}
    jq "${args[@]}" -L "$here" "include \"picker\"; $filter" "$file"
}

# ---- launcher: desktop entries, launched with gtk-launch ----

launcher_list() {
    for f in "$app_dir"/*.desktop; do
        # Only the [Desktop Entry] section: actions have Name= lines too.
        awk -F= -v id="$(basename "$f" .desktop)" '
            /^\[/ { main = ($0 == "[Desktop Entry]") }
            main && /^Name=/ && !name { name = substr($0, 6) }
            main && /^Terminal=true/ { term = 1 }
            main && /^NoDisplay=true/ { term = 1 }
            END { if (name && !term) print name "\t" id }' "$f"
    done | sort -u -t$'\t' -k1,1 | { fzf -f "$1" --delimiter '\t' --nth 1 || true; } |
        jq -R -s -c '[split("\n")[] | select(length > 0) | split("\t") | {label: .[0], value: .[1]}]'
}

launcher_select() {
    gtk-launch "$(jq -r '.value' <<<"$1")" >/dev/null 2>&1 &
}

# ---- clipboard: pinned texts, then cliphist history (newest first) ----

clipboard_list() {
    mkdir -p "$(dirname "$pin_file")"
    touch "$pin_file"
    {
        jq -R -c -L "$here" 'include "picker"; select(length > 0) | {label: clip_label, value: ., pinned: true}' <"$pin_file"
        # cliphist lines are "<id>\t<text>"; a pinned text is listed once, as the pin.
        cliphist list |
            awk -F'\t' -v pins="$pin_file" '
                BEGIN { while ((getline line < pins) > 0) pinned[line] }
                !(substr($0, index($0, "\t") + 1) in pinned)' |
            { fzf -f "$1" --delimiter '\t' --nth 2.. || true; } |
            jq -R -c -L "$here" 'include "picker"; select(length > 0) |
                {label: (split("\t")[1:] | join("\t") | clip_label), value: ., pinned: false}'
    } | jq -s -c '.'
}

clipboard_select() {
    local pinned value
    pinned=$(jq -r '.pinned' <<<"$1")
    value=$(jq -r '.value' <<<"$1")
    if [ "$pinned" = true ]; then
        printf '%s' "$value" | wl-copy
    else
        printf '%s' "$value" | cliphist decode | wl-copy
    fi
    wtype -s 60 -M ctrl -k v -m ctrl
}

clipboard_toggle_pin() {
    local text
    text=$(jq -r 'if .pinned then .value else .value | split("\t")[1:] | join("\t") end' <<<"$1")
    case $text in '[[ binary data '*) return ;; esac
    if grep -qxF -- "$text" "$pin_file"; then
        grep -vxF -- "$text" "$pin_file" >"$pin_file.tmp" || true
        mv "$pin_file.tmp" "$pin_file"
    else
        printf '%s\n' "$text" >>"$pin_file"
    fi
}

# ---- state ----

save() {
    cat >"$state.tmp"
    mv "$state.tmp" "$state"
    eww update picker="$(pj -c 'view' "$state")"
}

close() {
    hyprctl dispatch 'hl.dsp.submap("reset")' >/dev/null
    eww update picker_shown=false
    eww-windows.sh close picker
    rm -f "$state"
}

# Keys arrive faster than each run takes; handle them one at a time, in order.
exec 9>"$state.lock"
flock 9

case ${1:-} in
    launcher | clipboard)
        name=$1
        case $name in
            launcher) icon=$'\U000F0349' size=10 ;; # nf-md-magnify
            clipboard) icon=$'\U000F014C' size=8 ;; # nf-md-clipboard_outline
        esac
        "${name}_list" "" | jq -c --arg name "$name" --arg icon "$icon" --argjson size "$size" \
            '{name: $name, icon: $icon, size: $size, query: "", all: ., page: 0, index: 0}' | save
        hyprctl dispatch 'hl.dsp.submap("picker")' >/dev/null
        eww update picker_shown=true
        eww-windows.sh open picker --focused
        ;;
    close)
        close
        ;;
    search)
        [ -f "$state" ] || exit 0
        name=$(jq -r '.name' "$state")
        all=$("${name}_list" "${2:-}")
        jq -c --arg q "${2:-}" --argjson all "$all" '.query = $q | .all = $all | .page = 0 | .index = 0' "$state" | save
        ;;
    next | previous)
        [ -f "$state" ] || exit 0
        pj -c "$1" "$state" | save
        ;;
    next-page | previous-page)
        [ -f "$state" ] || exit 0
        d=1
        [ "$1" = previous-page ] && d=-1
        pj -c "turn($d)" "$state" | save
        ;;
    select)
        [ -f "$state" ] || exit 0
        name=$(jq -r '.name' "$state")
        if [ -n "${2:-}" ]; then
            entry=$(pj -c --argjson i "$2" '.index = $i | selected // empty' "$state")
        else
            entry=$(pj -c 'selected // empty' "$state")
        fi
        close
        [ -n "$entry" ] && "${name}_select" "$entry"
        ;;
    toggle-pin)
        [ -f "$state" ] || exit 0
        [ "$(jq -r '.name' "$state")" = clipboard ] || exit 0
        entry=$(pj -c 'selected // empty' "$state")
        [ -n "$entry" ] || exit 0
        clipboard_toggle_pin "$entry"
        all=$(clipboard_list "$(jq -r '.query' "$state")")
        # Stay on the same page; the selection may have moved with the pin.
        pj -c --argjson all "$all" '.all = $all | .page = ([.page, pages - 1] | min) | .index = ([.index, (slice | length) - 1] | min | [., 0] | max)' "$state" | save
        ;;
    *)
        echo "usage: picker.sh launcher|clipboard|close|search Q|next|previous|next-page|previous-page|select [N]|toggle-pin" >&2
        exit 1
        ;;
esac
