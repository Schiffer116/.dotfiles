#!/usr/bin/env sh

selected=$(
    fd --type d --hidden . ~/Documents ~/Downloads ~/.dotfiles ~/.config \
       --exclude .direnv --exclude .git --exclude node_modules \
    | fzf --layout=reverse --border=rounded --pointer="->" \
          --color='gutter:#11111B,bg+:#11111B' \
          --preview="eza --tree --icons -L2 --color=always {}"
)

if [ -z "$selected" ]; then
    exit 0
fi

selected_name=$(basename "$selected" | tr . _ | cut -c 1-7)
if ! tmux has-session -t="$selected_name" 2> /dev/null; then
    tmux new-session -ds "$selected_name" -c "$selected"
fi

if [ -z "$TMUX" ]; then
    tmux a -t "$selected_name"
else
    tmux switch-client -t "$selected_name"
fi

