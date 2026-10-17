# Claude Usage Widget

Shows how much of Claude's rate limits are used as two progress rings in the bar (session, then week), next to the hardware monitors; hovering shows the resets and the next reset. Data comes from `scripts/claude-usage.sh`, which reads `quota-axi --provider claude` without refreshing credentials.

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
Shown as `--` (and empty rings) when quota-axi is missing, fails, or returns no Claude windows (for example when Claude Code's sign-in has expired and needs a running session to refresh).
A window with no data shows `--` only for its own fields, and one with no reset scheduled (such as a session after hours idle) shows `--` for its reset; the next reset uses whichever resets are known.

# Claude Agents Widget

Shows how many Claude Agents are in each status, as icon and count pairs after the usage rings; hovering lists every status. Data comes from `scripts/claude-agents.sh`, which runs `berthier counts` (Berthier's Main Loop refreshes it about every 10s). Agent, Main Loop and Fleet State are Berthier's terms, defined in Berthier's own `CONTEXT.md`.

## Language

**Working**, **Blocked**, **Done**, **Idle**, **Unknown**:
The Agent's status as herdr reports it. Blocked means the Agent waits on the user, so it is the one status drawn as a filled red pill.

**Gone**:
An Agent whose pane vanished; Berthier's Main Loop Revives it unless the user exited it on purpose.

**Shown**:
Working always appears, even at 0, so the widget never disappears; every other status appears only when its count is above 0.

**Unavailable**:
Shown as a robot and `--` when `berthier counts` is missing or fails, or reports `available: false` because the Main Loop has not updated the Fleet State for 30s or more.
