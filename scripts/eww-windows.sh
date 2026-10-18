#!/usr/bin/env bash
# The one place that opens and closes eww windows.
#
#   eww-windows.sh sync                                       match the windows to the outputs
#   eww-windows.sh open <window> --focused|--all|--screen <output>   open a popup
#   eww-windows.sh close <window>                             close a popup on every output
#   eww-windows.sh toggle <window> --screen <output>          close it there, or move it there
#
# sync opens each enabled output's bar and other windows from the monitor table that hyprland.lua
# writes to $XDG_RUNTIME_DIR/monitors.json (.config/hypr/monitors.lua), and closes those of outputs
# that went away, along with any popup left on them. Hyprland runs it at login and on every output
# change; it is safe to run any number of times. What to open and close is pure jq in
# eww-windows.jq (bash scripts/eww-windows.test.sh).
#
# Windows are pinned to their output: when an output goes away Hyprland moves its layers to
# another one and eww never moves them back, so they are closed with the output and reopened
# once it is back. Popups get the id <window>@<output> so sync knows where they are.
set -euo pipefail
here=$(dirname "$(readlink -f "$0")")

table=${MONITORS_JSON:-$XDG_RUNTIME_DIR/monitors.json}
lock=${EWW_WINDOWS_LOCK:-$XDG_RUNTIME_DIR/eww-windows.lock}

usage() {
    echo "usage: eww-windows.sh sync | open WINDOW --focused|--all|--screen OUTPUT | close WINDOW | toggle WINDOW --screen OUTPUT" >&2
    exit 2
}

# Two calls from back-to-back events must not both open the same window.
exec 9>"$lock"
flock 9

# This script owns the eww daemon: it starts it when none answers. Every other eww call here
# passes --no-daemonize, because a plain `eww open` that fails (as it does while the daemon is
# still loading, or before GTK knows a new output) starts a second daemon of its own, and the
# bar variables then split between the two.
if ! eww ping >/dev/null 2>&1; then
    eww daemon 9>&-
fi
for _ in $(seq 50); do
    eww ping >/dev/null 2>&1 && break
    sleep 0.1
done

open_ids() {
    eww active-windows | cut -d: -f1
}

# open_window ID CONFIG OUTPUT [eww open args...]
open_window() {
    local id=$1 config=$2 output=$3
    shift 3
    # Right after an output appears GTK may not know it yet; eww exits non-zero until it does.
    for _ in $(seq 20); do
        eww --no-daemonize open "$config" --id "$id" --screen "$output" "$@" >/dev/null && return
        sleep 0.25
    done
    echo "eww-windows.sh: could not open $id" >&2
    return 1
}

close_popup() {
    open_ids | awk -v prefix="$1@" 'index($0, prefix) == 1' | xargs -r eww --no-daemonize close
}

# outputs TARGET [OUTPUT]: the output names a popup target means.
outputs() {
    case $1 in
        --focused) hyprctl activeworkspace -j | jq -r '.monitor' ;;
        --all) hyprctl monitors -j | jq -r '.[].name' ;;
        --screen) [ -n "${2:-}" ] || usage; echo "$2" ;;
        *) usage ;;
    esac
}

case ${1:-} in
    sync)
        active=$(hyprctl monitors -j | jq -c '[.[].name]')
        plan=$(jq -c -L "$here" --argjson active "$active" --argjson open "$(open_ids | jq -R . | jq -sc .)" \
            'include "eww-windows"; plan($active; $open)' "$table")
        jq -r '.close[]' <<<"$plan" | xargs -r eww --no-daemonize close
        jq -r '.open[] | [.id, .config, .output, .workspace_base // ""] | @tsv' <<<"$plan" |
            while IFS=$'\t' read -r id config output base; do
                if [ "$config" = bar ]; then
                    open_window "$id" "$config" "$output" --arg "monitor_name=$output" --arg "workspace_base=$base" || true
                else
                    open_window "$id" "$config" "$output" || true
                fi
            done
        ;;
    open)
        [ -n "${2:-}" ] || usage
        window=$2
        open=$(open_ids)
        for output in $(outputs "${3:-}" "${4:-}"); do
            id="$window@$output"
            grep -qxF "$id" <<<"$open" || open_window "$id" "$window" "$output"
        done
        ;;
    close)
        [ -n "${2:-}" ] || usage
        close_popup "$2"
        ;;
    toggle)
        [ -n "${2:-}" ] && [ "${3:-}" = --screen ] && [ -n "${4:-}" ] || usage
        window=$2 output=$4
        if open_ids | grep -qxF "$window@$output"; then
            eww --no-daemonize close "$window@$output"
        else
            close_popup "$window"
            open_window "$window@$output" "$window" "$output"
        fi
        ;;
    *)
        usage
        ;;
esac
