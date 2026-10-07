#!/bin/bash
# Plays a chime, then speaks a message via Piper TTS. Used by Claude Code's
# Stop and Notification hooks (see ~/.claude/settings.json).
set -u

SOUND_FILE="$1"
MESSAGE="$2"

VENV="$HOME/.local/share/piper-tts/venv"
VOICE="$HOME/.local/share/piper-tts/voices/en_US-amy-medium.onnx"

paplay "$SOUND_FILE" 2>/dev/null

echo "$MESSAGE" \
  | "$VENV/bin/piper" -m "$VOICE" --output-raw 2>/dev/null \
  | paplay --raw --format=s16le --rate=22050 --channels=1 2>/dev/null
