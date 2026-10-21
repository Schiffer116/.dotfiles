#!/bin/bash
# Claude Code status line: "Model | 5h: N% | 7d: N% | Ctx: N% | Cost: $N", skipping any
# field the session JSON on stdin does not carry.
set -u

input=$(cat)
# Feed Berthier's per-Corps quota ledger; never slows or breaks the line.
berthier sample <<<"$input" >/dev/null 2>&1 &

{
  read -r model
  read -r five
  read -r week
  read -r ctx
  read -r cost
} < <(jq -r '
  .model.display_name,
  .rate_limits.five_hour.used_percentage,
  .rate_limits.seven_day.used_percentage,
  .context_window.used_percentage,
  .cost.total_cost_usd
  | . // ""' <<<"$input")

parts=()
[ -n "$model" ] && parts+=("$model")
[ -n "$five" ] && parts+=("$(printf '5h: %.0f%%' "$five")")
[ -n "$week" ] && parts+=("$(printf '7d: %.0f%%' "$week")")
[ -n "$ctx" ] && parts+=("$(printf 'Ctx: %.0f%%' "$ctx")")
[ -n "$cost" ] && parts+=("$(printf 'Cost: $%.2f' "$cost")")

out=$(printf '%s | ' "${parts[@]}")
printf '%s' "${out% | }"
