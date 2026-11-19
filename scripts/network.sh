#!/usr/bin/env bash
# network.sh: eww listener for the bar's network pill. Prints {"name": ..., "type": ...} of the first
# active NetworkManager connection at start and whenever it changes.
#
# eww does not stop its listeners when the daemon dies (it dies with Hyprland), and `nmcli connection
# monitor` only wakes on network events, so a listener can outlive its daemon for hours. This one checks
# every few seconds that the eww daemon that started it is still its parent, and exits when it is not.
set -euo pipefail

parent=$PPID

exec 3< <(exec nmcli connection monitor)
monitor_pid=$!
trap 'kill "$monitor_pid" 2>/dev/null' EXIT

last=
emit() {
  local name type json
  name=$(nmcli --get-values NAME connection show --active | head -1)
  type=$(nmcli --get-values TYPE connection show --active | head -1)
  json=$(jq -cn --arg name "$name" --arg type "$type" '{name: $name, type: $type}')
  if [ "$json" != "$last" ]; then
    printf '%s\n' "$json"
    last=$json
  fi
}

emit
while :; do
  if read -r -t 5 -u 3 _; then
    emit
  elif (($? <= 128)); then
    exit 0 # nmcli monitor ended
  fi
  [ "$(ps -o ppid= -p $$ | tr -d ' ')" = "$parent" ] || exit 0
done
