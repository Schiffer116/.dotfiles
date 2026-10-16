#!/usr/bin/env sh

languages='[
  {
    "symbol": "E",
    "ime": "keyboard-us"
  },
  {
    "symbol": "J",
    "ime": "mozc"
  },
  {
    "symbol": "V",
    "ime": "unikey"
  }
]'

get_symbol() {
    cur_lang="$(fcitx5-remote -n)"
    echo "$languages" | jq -r '.[] | select(.ime == "'"$cur_lang"'") | .symbol'
}

get_languages()  {
    echo "$languages" | jq '[ .[] | .symbol ]'
}

symbol_to_ime() {
    echo "$languages" | jq -r '.[] | select(.symbol == "'"$1"'") | .ime'
}

set_language() {
    fcitx5-remote -s "$1"
}

# The bar reads `get` once when eww starts (cur_lang in bar/widgets.yuck) and `set` pushes
# each switch, since fcitx5 has no signal for it. Its own trigger keys (Zenkaku_Hankaku,
# Hangul) bypass this; they are not on this keyboard.
case $1 in
    get) get_symbol ;;
    set)
        set_language "$(symbol_to_ime "$2")"
        eww update cur_lang="$(get_symbol)"
        ;;
esac
