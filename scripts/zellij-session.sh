#!/usr/bin/sh

selected=$(find ~/Documents ~/Downloads ~/.dotfiles -type d \
            | fzf --layout=reverse --border=rounded --pointer="->" --color='gutter:#11111B,bg+:#11111B' \
                    --preview="exa --tree --icons -L2 {}")
[ -z "$selected" ] && exit 0

selected_name=$(basename "$selected")

cd "$selected" || exit;
if [ "$ZELLIJ" = 0 ]; then
    echo "zellij attach --create $selected_name" | wl-copy
    zellij kill-session "$ZELLIJ_SESSION_NAME"
fi
zellij attach --create "$selected_name"
