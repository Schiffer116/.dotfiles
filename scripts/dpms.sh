#!/usr/bin/env bash
# dpms.sh on|off: DPMS every enabled output. "on" skips the internal panel while the lid is
# closed (hyprland.lua keeps it off or disabled then); hypridle calls this.
set -euo pipefail

action=${1:?usage: dpms.sh on|off}

lid_closed=false
grep -q closed /proc/acpi/button/lid/LID0/state 2>/dev/null && lid_closed=true

internal=$(jq -r '.[] | select(.internal) | .name' "$XDG_RUNTIME_DIR/monitors.json")

hyprctl monitors -j | jq -r '.[].name' | while read -r output; do
    if [ "$action" = on ] && $lid_closed && [ "$output" = "$internal" ]; then
        continue
    fi
    hyprctl dispatch "hl.dsp.dpms({ action = '$action', monitor = '$output' })" >/dev/null
done
