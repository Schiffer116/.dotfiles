#!/usr/bin/env sh

cache_file="${XDG_CACHE_HOME:-$HOME/.cache}/tmux-session-dirs"

query_dirs() {
    fd --type d --hidden . ~/Documents ~/Downloads ~/.dotfiles ~/.config \
       --exclude .direnv --exclude .git --exclude node_modules
}

# `tmux-session.sh --cache` refreshes the cached directory list and exits.
# Hyprland runs this on startup so the interactive picker opens instantly.
if [ "$1" = "--cache" ]; then
    mkdir -p "$(dirname "$cache_file")"
    query_dirs > "$cache_file.tmp" && mv "$cache_file.tmp" "$cache_file"
    exit 0
fi

if [ -s "$cache_file" ]; then
    dirs=$(cat "$cache_file")
else
    dirs=$(query_dirs)
fi

selected=$(
    printf '%s\n' "$dirs" \
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
