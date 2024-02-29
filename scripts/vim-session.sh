#!/usr/bin/env sh

session_dir="$XDG_CACHE_HOME/nvim/sessions"

dir_list=$(find ~/Documents ~/Downloads ~/.dotfiles -type d)

case $1 in 
    "--list-only")
        echo "$dir_list"
        exit 0
        ;;
    "--create-only")
        selected=$2
        ;;
    *) 
        selected=$(
            echo "$dir_list" | \
            fzf --layout=reverse --border=rounded --pointer="->" --color='gutter:#11111B,bg+:#11111B' \
                --preview="exa --tree --icons -L2 --color=always {}"
        )
esac

[ -z "$selected" ] && exit 0

selected_name=$(basename "$selected")

if ! [ -e "$session_dir/$selected_name.vim" ]; then 
    cd "$session_dir" || exit
    nvim -c "cd $selected" -c "te" -c "mks $session_dir/$selected_name.vim" -c "q"
fi

if [ "$1" != "--create-only" ]; then
    nvim -S "$session_dir/$selected_name.vim"
fi
