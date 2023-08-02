#!/bin/bash

SCRIPTSDIR=$HOME/scripts

# Kill already running process
_ps=(waybar mako)
for _prs in "${_ps[@]}"; do
	if [[ $(pidof "${_prs}") ]]; then
		killall -9 "${_prs}"
	fi
done

# Apply themes
"${SCRIPTSDIR}"/gtkthemes &

# Lauch notification daemon (mako)
"${SCRIPTSDIR}"/notifications &

# Lauch statusbar (waybar)
"${SCRIPTSDIR}"/statusbar &

sleep 2
waybar &
ibus-daemon
