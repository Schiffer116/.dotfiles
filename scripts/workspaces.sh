#!/usr/bin/env sh 

before=$(hyprctl activeworkspace -j | jq '.id')
case $1 in
    "--change") hyprctl dispatch workspace "$2" ;;
    "--move") hyprctl dispatch movetoworkspace "$2" ;;
esac
after=$(hyprctl activeworkspace -j | jq '.id')

eww update ws_cur="$after" ws_prv="$before"
