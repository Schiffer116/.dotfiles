#!/usr/bin/env bash
# Open and close the per-output eww windows (each output's bar and its other windows) so they
# match the outputs Hyprland has enabled right now. The windows come from the monitor table that
# hyprland.lua writes to $XDG_RUNTIME_DIR/monitors.json (.config/hypr/monitors.lua).
# Hyprland runs `eww-windows.sh sync` at login and on every output change; it is safe to run
# any number of times, and only touches windows the table names.
#
# Windows are pinned to their output: when an output goes away Hyprland moves its layers to
# another one and eww never moves them back, so they are closed with the output and reopened
# once it is back.
set -euo pipefail

table=${MONITORS_JSON:-$XDG_RUNTIME_DIR/monitors.json}
lock=${EWW_WINDOWS_LOCK:-$XDG_RUNTIME_DIR/eww-windows.lock}

# Two syncs from back-to-back output events must not both open the same window.
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

active=$(hyprctl monitors -j | jq -c '[.[].name]')
open=$(eww active-windows | cut -d: -f1)

# One line per window the table wants open now: id, config, output, workspace base (bars only).
wanted=$(jq -r --argjson active "$active" '
    .[] | select(.name as $n | $active | index($n)) |
    ([.bar, "bar", .name, .workspace_base] | @tsv),
    (.windows[] as $w | [$w, $w, .name, ""] | @tsv)' "$table")

# Every window id the table manages, on any output.
managed=$(jq -r '.[] | .bar, .windows[]' "$table")

while IFS= read -r id; do
    [ -n "$id" ] || continue
    if grep -qxF "$id" <<<"$open" && ! cut -f1 <<<"$wanted" | grep -qxF "$id"; then
        eww --no-daemonize close "$id"
    fi
done <<<"$managed"

while IFS=$'\t' read -r id config output base; do
    [ -n "$id" ] || continue
    grep -qxF "$id" <<<"$open" && continue
    args=()
    if [ "$config" = bar ]; then
        args=(--arg "monitor_name=$output" --arg "workspace_base=$base")
    fi
    # Right after an output appears GTK may not know it yet; eww exits non-zero until it does.
    for _ in $(seq 20); do
        eww --no-daemonize open "$config" --id "$id" --screen "$output" "${args[@]}" >/dev/null && break
        sleep 0.25
    done
done <<<"$wanted"
