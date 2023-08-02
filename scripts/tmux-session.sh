#! /bin/sh
target=$(find . -type d -print | fzf) &&
cd "$target" && 
dir_name=$(basename "$PWD") && 
session_name=$(echo "$dir_name" | cut -c 1-7) &&
tmux new -s "$session_name" && 
cd - > /dev/null || exit
