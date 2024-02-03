#!/bin/sh

languages='[
    {"symbol":"E","ime":"keyboard-us"},
    {"symbol":"J","ime":"mozc"},
    {"symbol":"V","ime":"unikey"}
]'

get_symbol() {
    cur_lang="$(fcitx5-remote -n)"
    index=$(echo "$languages" | jq "map(.ime == \"$cur_lang\") | index(true)")
    echo "$languages" | jq -r ".[$index].symbol"
}

set_lang() {
    fcitx5-remote -s $1
    eww update cur_lang=$(get_symbol $1)
}

case $1 in
    "--get") get_symbol ;;
    "--next") cycle_lang ;;
    "--set") 
        case $2 in
            "E") set_lang "keyboard-us" ;;
            "J") set_lang "mozc" ;;
            "V") set_lang "unikey" ;;
        esac
        ;;
esac

eww update cur_lang="$(get_symbol)"
