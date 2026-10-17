#!/bin/bash
# Reports how many Claude Agents are in each status, as one JSON object for eww.
# Data comes from `berthier counts`; when it is missing or fails, every count is 0
# and "available" is false, the same as when Berthier's Main Loop has gone stale.
set -uo pipefail

BERTHIER="$(command -v berthier || echo "$HOME/.local/bin/berthier")"

"$BERTHIER" counts 2>/dev/null ||
  jq -nc '{available: false, working: 0, blocked: 0, done: 0, idle: 0, unknown: 0, gone: 0}'
