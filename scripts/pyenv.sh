#!/usr/bin/env sh

# notify-send "$(dirname $0)"
static="$(dirname "$0")"
cp "$static/static/.envrc" "$static/static/flake.nix" "$(pwd)"
direnv allow
