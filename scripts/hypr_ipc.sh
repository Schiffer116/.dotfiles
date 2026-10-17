#!/usr/bin/env sh
# eww deflisten source for the bar (hypr_state in bar/widgets.yuck). Prints the bar's
# Hyprland state as one JSON line at start and after every workspace or monitor change,
# so a restarted eww daemon gets it back on its own:
#   {"monitors": [{"name", "currentWorkspace", "previousWorkspace"}]}

# Live monitors, keeping each one's previous workspace across rebuilds.
read_monitors() {
    hyprctl monitors -j | jq -c --argjson old "${monitors:-[]}" 'map(.name as $n | {
        name: $n,
        currentWorkspace: .activeWorkspace.id,
        previousWorkspace: (($old[] | select(.name == $n) | .previousWorkspace) // .activeWorkspace.id)
    })'
}

emit() {
    jq -nc --argjson monitors "$monitors" '{monitors: $monitors}'
}

monitors=$(read_monitors)
emit

# eww stops a deflisten by killing this shell only, so socat runs as a tracked background job
# feeding a FIFO (not a pipeline, whose processes would outlive us) and is killed on exit.
fifo="$XDG_RUNTIME_DIR/hypr_ipc.$$.fifo"
mkfifo "$fifo"
socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR"/hypr/"$HYPRLAND_INSTANCE_SIGNATURE"/.socket2.sock >"$fifo" &
socat_pid=$!
trap 'kill "$socat_pid" 2>/dev/null; rm -f "$fifo"' EXIT
trap 'exit 0' INT TERM HUP

while read -r line; do
    case $line in
        'workspace>>'*)
            current_monitor=$(hyprctl activeworkspace -j | jq -r '.monitor')
            current_workspace=${line#workspace>>}
            monitors=$(printf '%s' "$monitors" | jq -c --arg m "$current_monitor" --arg w "$current_workspace" '
                map(if .name == $m then
                        .previousWorkspace = .currentWorkspace | .currentWorkspace = ($w | tonumber? // $w)
                    else . end)')
            emit
            ;;
        'monitoradded>>'* | 'monitorremoved>>'*)
            monitors=$(read_monitors)
            emit
            ;;
    esac
done <"$fifo"
