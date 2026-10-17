#!/bin/bash
# Reports how many Claude Agents are in each status, as one JSON object for eww.
# Data comes from `berthier counts`, including "report": Berthier's Fleet report, one line
# per Project ("skipli: needs you - review the PR"), possibly empty. "report_markup" is the
# same report as Pango markup for the tooltip: Project name in Claude orange, its state
# after it (red when it needs the user), both padded into columns (the font is monospace);
# a line not in that shape is kept as plain text.
# When berthier is missing or fails, every count is 0, the report is empty and "available"
# is false, the same as when the Main Loop has gone stale.
set -uo pipefail

BERTHIER="$(command -v berthier || echo "$HOME/.local/bin/berthier")"

counts=$("$BERTHIER" counts 2>/dev/null) ||
  counts='{"available": false, "working": 0, "blocked": 0, "done": 0, "idle": 0, "unknown": 0, "gone": 0, "report": ""}'

jq -c '
  def esc: gsub("&"; "&amp;") | gsub("<"; "&lt;") | gsub(">"; "&gt;");
  def span($color): "<span foreground=\"\($color)\">\(esc)</span>";
  def pad($n): . + (" " * ($n - length));
  [(.report // "") | split("\n")[] | select(length > 0)
    | capture("^(?<project>[^:]+): (?<state>.+?) - (?<detail>.*)$") // {text: .}] as $lines
  | ([$lines[].project // "" | length] | max // 0) as $pw
  | ([$lines[].state // "" | length] | max // 0) as $sw
  | .report_markup = ([$lines[]
      | if .text then .text | esc
        else "\(.project | pad($pw) | span("#d97757"))  \(.state as $s | $s | pad($sw) | span(if $s == "needs you" then "#ed5555" else "#a4b9ef" end))  \(.detail | esc)"
        end] | join("\n"))' <<<"$counts"
