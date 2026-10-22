#!/usr/bin/env sh

# shellcheck source=/dev/null disable=SC2154
. ~/.config/theme/palette.sh

# swaylock wants bare hex; alpha is two more digits.
hex() { printf %s "${1#\#}"; }

swaylock  \
    --image ~/Pictures/arts/twilight.png \
    --clock \
	--indicator-radius 147 \
	--indicator-thickness 7 \
	--ignore-empty-password \
    --ring-color "$(hex "$theme_surface0")" \
	--key-hl-color "$(hex "$theme_accent")" \
	--text-color "$(hex "$theme_text")" \
	--line-color "$(hex "$theme_bg")00" \
	--inside-color "$(hex "$theme_bg")88" \
	--separator-color "$(hex "$theme_bg")00"
