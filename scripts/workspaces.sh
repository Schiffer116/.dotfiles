#!/bin/sh 

before=$(hyprctl activeworkspace -j | jq '.id')
hyprctl dispatch workspace "$1" 
after=$(hyprctl activeworkspace -j | jq '.id')

eww update ws_cur="$after" ws_prv="$before"
