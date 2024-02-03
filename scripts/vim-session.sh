#!/bin/sh

session_dir="$HOME/Documents/vim-sessions"

selected=$(
    find ~/Documents ~/Downloads ~/.dotfiles -type d | \
    fzf --layout=reverse --border=rounded --pointer="->" --color='gutter:#11111B,bg+:#11111B' \
        --preview="exa --tree --icons -L2 --color=always {}"
)
[ -z "$selected" ] && exit 0

selected_name=$(basename "$selected" | tr . -)

if [ -z "$(cat "$session_dir/$selected_name.vim" 2> /dev/null )" ]; then 
    cd "$session_dir" || exit
    nvim -c "cd $selected" -c "te" -c "mks $session_dir/$selected_name.vim" -c "q"
fi

nvim -S "$session_dir/$selected_name.vim"
