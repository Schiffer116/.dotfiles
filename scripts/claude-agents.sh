#!/bin/bash
# Reports how many Claude Agents are in each status, as one JSON object for eww.
# Data comes from `berthier counts`, including "report": Berthier's Army report, one line
# per Corps ("skipli: needs you - review the PR"), needs-you first, possibly empty. It is
# also split into "corps" [{name, state, detail}] for the Army desktop window; a line not
# in that shape keeps its whole text as the detail.
# When berthier is missing or fails, every count is 0, the report is empty and "available"
# is false, the same as when the Main Loop has gone stale.
set -uo pipefail

BERTHIER="$(command -v berthier || echo "$HOME/.local/bin/berthier")"

counts=$("$BERTHIER" counts 2>/dev/null) ||
  counts='{"available": false, "working": 0, "blocked": 0, "done": 0, "idle": 0, "unknown": 0, "gone": 0, "report": ""}'

jq -c '.corps = [(.report // "") | split("\n")[] | select(length > 0)
  | capture("^(?<name>[^:]+): (?<state>.+?) - (?<detail>.*)$") // {name: "", state: "", detail: .}]' <<<"$counts"
