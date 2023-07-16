#!/bin/bash

SCRIPTSDIR=$HOME/.config/hypr/scripts

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

#dex $HOME/.config/autostart/arcolinux-welcome-app.desktop &

sleep 2
waybar &
ibus-daemon

#insync start &
#nm-applet-indicator
