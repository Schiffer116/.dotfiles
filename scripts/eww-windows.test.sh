#!/usr/bin/env bash
# Tests for eww-windows.jq, the eww window sync's plan: bash scripts/eww-windows.test.sh
set -euo pipefail
here=$(dirname "$(readlink -f "$0")")
failures=0

table='[
  {"name": "eDP-1", "workspace_base": 0, "bar": "laptop_bar", "windows": ["monitor", "quote"]},
  {"name": "HDMI-A-1", "workspace_base": 10, "bar": "ew270q_bar", "windows": []}
]'

# check NAME ACTIVE OPEN EXPECTED: plan for the table above with ACTIVE outputs and OPEN window ids.
check() {
    local got
    got=$(jq -n -c -L "$here" --argjson table "$table" --argjson active "$2" --argjson open "$3" \
        'include "eww-windows"; $table | plan($active; $open)')
    if [ "$got" = "$4" ]; then
        echo "ok   $1"
    else
        echo "FAIL $1: got $got, want $4"
        failures=$((failures + 1))
    fi
}

check "login opens every window of every output" '["eDP-1","HDMI-A-1"]' '[]' \
    '{"close":[],"open":[{"id":"laptop_bar","config":"bar","output":"eDP-1","workspace_base":0},{"id":"monitor","config":"monitor","output":"eDP-1"},{"id":"quote","config":"quote","output":"eDP-1"},{"id":"ew270q_bar","config":"bar","output":"HDMI-A-1","workspace_base":10}]}'
check "nothing to do when all is open" '["eDP-1","HDMI-A-1"]' '["laptop_bar","monitor","quote","ew270q_bar"]' \
    '{"close":[],"open":[]}'
check "output removed closes its windows" '["HDMI-A-1"]' '["laptop_bar","monitor","quote","ew270q_bar"]' \
    '{"close":["laptop_bar","monitor","quote"],"open":[]}'
check "output added opens only its windows" '["eDP-1","HDMI-A-1"]' '["laptop_bar","monitor","quote"]' \
    '{"close":[],"open":[{"id":"ew270q_bar","config":"bar","output":"HDMI-A-1","workspace_base":10}]}'
check "popup on a removed output closes" '["eDP-1"]' '["laptop_bar","monitor","quote","powermenu@eDP-1","powermenu@HDMI-A-1"]' \
    '{"close":["powermenu@HDMI-A-1"],"open":[]}'
check "popup on an unlisted output closes when it goes" '["eDP-1"]' '["laptop_bar","monitor","quote","picker@DP-2"]' \
    '{"close":["picker@DP-2"],"open":[]}'
check "windows the table does not name are left alone" '["eDP-1"]' '["laptop_bar","monitor","quote","scratch"]' \
    '{"close":[],"open":[]}'

[ "$failures" -eq 0 ] || exit 1
