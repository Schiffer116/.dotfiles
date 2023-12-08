#!/bin/sh

languages="keyboard-us:E
unikey:V
mozc:J"

get_symbol() {
    cur_lang="$(fcitx5-remote -n)"
    for language in $languages; do
        if [ "$cur_lang" = "${language%:*}" ]; then
            echo "${language#*:}"
        fi
    done
}

set_lang() {
    fcitx5-remote -s "$1"
    pkill -RTMIN+4 waybar
}

cycle_lang() {
    last_lang=$(echo "$languages" | tail --lines=1 | cut -d ':' -f1 )
    cur_symbol=$(get_symbol)
    for language in $languages; do
        if [ "$cur_symbol" = "${language#*:}" ]; then
            break
        fi
        last_lang=${language%:*}
    done
    fcitx5-remote -s "$last_lang"
    pkill -RTMIN+4 waybar
}

case "$1" in
    "--get") get_symbol ;;
    "--next") cycle_lang ;;
    "--en") set_lang "keyboard-us" ;;
    "--vn") set_lang "unikey" ;;
    "--jp") set_lang "mozc" ;;
esac
