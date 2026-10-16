#!/bin/bash
# Reports Claude usage for the session (five-hour) and week (seven-day)
# rate-limit windows plus the next reset, as one JSON object for eww.
# The *_percent fields are numbers for the bar's progress rings (0 when unknown).
# Reads quota-axi without refreshing credentials, reusing a reading for up
# to 5 minutes so frequent polls only keep the countdown current.
set -uo pipefail

QUOTA_AXI="$(command -v quota-axi || echo "$HOME/.local/bin/quota-axi")"

unavailable() {
  jq -nc '{available: false,
           session_percent: 0, week_percent: 0,
           session_used: "--", session_reset: "--",
           week_used: "--", week_reset: "--",
           next_reset_window: "--", next_reset_at: "--", next_reset_in: "--"}'
  exit 0
}

# Prints the time left until the given epoch as "2d 4h", "3h 12m" or "45m".
countdown() {
  local left=$(( $1 - $(date +%s) ))
  [ "$left" -lt 0 ] && left=0
  local days=$(( left / 86400 )) hours=$(( left % 86400 / 3600 )) mins=$(( left % 3600 / 60 ))
  if [ "$days" -gt 0 ]; then
    echo "${days}d ${hours}h"
  elif [ "$hours" -gt 0 ]; then
    echo "${hours}h ${mins}m"
  else
    echo "${mins}m"
  fi
}

[ -x "$QUOTA_AXI" ] || unavailable

report=$("$QUOTA_AXI" --provider claude --json --no-credential-refresh --max-age 5m 2>/dev/null) || unavailable

# Prints "<used percent> <resetsAt>" for the given window id, or nothing.
# resetsAt is omitted when the window has no reset scheduled.
window() {
  jq -r --arg id "$1" '.providers[]? | select(.provider == "claude") | .windows[]?
    | select(.id == $id and .percentRemaining != null)
    | "\(100 - .percentRemaining)% \(.resetsAt // "")"' <<< "$report" 2>/dev/null | head -1
}

read -r session_used session_reset_iso <<< "$(window five_hour)"
read -r week_used week_reset_iso <<< "$(window seven_day)"
[ -n "${session_used:-}" ] || [ -n "${week_used:-}" ] || unavailable

session_epoch=$( [ -n "${session_reset_iso:-}" ] && date -d "$session_reset_iso" +%s 2>/dev/null )
week_epoch=$( [ -n "${week_reset_iso:-}" ] && date -d "$week_reset_iso" +%s 2>/dev/null )

next_window="--" next_epoch=""
if [ -n "$session_epoch" ]; then
  next_window="Session" next_epoch=$session_epoch
fi
if [ -n "$week_epoch" ] && { [ -z "$next_epoch" ] || [ "$week_epoch" -lt "$next_epoch" ]; }; then
  next_window="Week" next_epoch=$week_epoch
fi

# Formats the given epoch with the given date format, or prints "--".
at() {
  if [ -n "$1" ]; then date -d "@$1" "$2"; else echo "--"; fi
}

jq -nc \
  --arg session_used "${session_used:---}" --arg session_reset "$(at "$session_epoch" '+%H:%M')" \
  --arg week_used "${week_used:---}" --arg week_reset "$(at "$week_epoch" '+%a %H:%M')" \
  --arg next_window "$next_window" --arg next_at "$(at "$next_epoch" '+%a %H:%M')" \
  --arg next_in "$([ -n "$next_epoch" ] && countdown "$next_epoch" || echo "--")" \
  '{available: true,
    session_percent: ($session_used | rtrimstr("%") | tonumber? // 0),
    week_percent: ($week_used | rtrimstr("%") | tonumber? // 0),
    session_used: $session_used, session_reset: $session_reset,
    week_used: $week_used, week_reset: $week_reset,
    next_reset_window: $next_window, next_reset_at: $next_at, next_reset_in: $next_in}'
