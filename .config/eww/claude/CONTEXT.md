# Claude Usage Widget

Shows how much of Claude's rate limits are used and when they next reset, on the eww background layer. Data comes from `scripts/claude-usage.sh`, which reads `quota-axi --provider claude` without refreshing credentials.

## Language

**Session**:
Claude's five-hour rate-limit window (`five_hour` in quota-axi).
_Avoid_: Current conversation, Claude Code session

**Week**:
Claude's seven-day rate-limit window (`seven_day` in quota-axi).
_Avoid_: Calendar week

**Used**:
The percentage of a window already spent: 100 minus quota-axi's `percentRemaining`.
_Avoid_: Remaining, left

**Next reset**:
Whichever of the session and week resets comes first, shown as a countdown and a local time.

**Unavailable**:
Shown as `--` when quota-axi is missing, fails, or returns no Claude windows (for example when Claude Code's sign-in has expired and needs a running session to refresh).
A window with no data shows `--` only for its own fields, and one with no reset scheduled (such as a session after hours idle) shows `--` for its reset; the next reset uses whichever resets are known.
