#!/bin/bash



apply_themes() {
    CURSOR='Bibata-Modern-Ice'
    SCHEMA='gsettings set org.gnome.desktop.interface'
	${SCHEMA} cursor-theme "$CURSOR"
}

apply_themes
mako &
waybar &
ibus-daemon
