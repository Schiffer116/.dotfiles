#!/bin/bash
# Desktop notification, chime, then the message spoken via Piper TTS.
# Usage: speak.sh "<message>". Each output is skipped when unavailable, so on
# the headless box this is a no-op. DRY_RUN=1 prints instead of acting.
set -u

msg="${1:?usage: speak.sh \"<message>\"}"
sound=/usr/share/sounds/deepin/stereo/dialog-error.wav
piper="$HOME/.local/share/piper-tts/venv/bin/piper"
voice="$HOME/.local/share/piper-tts/voices/en_US-amy-medium.onnx"

if [ "${DRY_RUN:-0}" = 1 ]; then
  printf 'message: %s\nsound: %s\n' "$msg" "$sound"
  exit 0
fi

if [ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ] && command -v notify-send >/dev/null; then
  notify-send -a 'Claude Code' 'Claude Code' "$msg"
fi

command -v paplay >/dev/null || exit 0
# Detached so the caller returns before the audio finishes.
(
  paplay "$sound"
  if [ -x "$piper" ] && [ -f "$voice" ]; then
    "$piper" -m "$voice" --output-raw <<<"$msg" \
      | paplay --raw --format=s16le --rate=22050 --channels=1
  fi
) </dev/null >/dev/null 2>&1 &
