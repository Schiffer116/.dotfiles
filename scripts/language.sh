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

ime="$(symbol_to_ime "$2")"
set_language "$ime"
eww update cur_lang="$(get_symbol)"
