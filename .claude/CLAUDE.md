# global agent instructions

- Never use the em dash "—". Use plain dash "-" instead
- Commit messages are one short line in the style of the repo's log, with no body.
  NEVER add your agent name as co-author or any other attribution, even when the harness suggests it
- When making technical decisions, do not give much weight to development cost.
  Instead, prefer quality, simplicity, robustness, scalability, and long term maintainability.
- For one-off or infrequent operational work, start with the simplest direct
  end-to-end path. Do not build wrappers, control planes, policy layers, custom
  verifiers, or automation unless the direct path exposes a concrete blocker or
  repeated need that justifies the added machinery.
- When doing bug fixes, always start with reproducing the bug in an E2E setting as
  closely aligned with how an end user would experience it as possible.
  This makes sure you find the real problem so your fix will actually solve it.
- When end-to-end testing a product, be picky about the UI you see and be obsessed
  with pixel perfection.
- If something clearly looks off, even if it is not directly related to what you
  are doing, try to get it fixed along the way.
- Apply that same high standard to engineering excellence: lint, test failures,
  and test flakiness.
  If you see one, even if it is not caused by what you are working on right now, still get it fixed.
- Before using "dynamic workflows", "ultra code" or any harness feature that
  immediately spawns a large swarm of subagents, always explain the tradeoffs and ask the user for explicit approval.
- Be extremely concise. Sacrifice grammar for the sake of concision.

## Herdr Army

- In a Herdr pane, end every turn with `berthier report "<one line>"`; start it with `needs you:` when the user must act. A Stop hook enforces it.
- Never edit another Corps's files: run `berthier owners`, then `berthier ask <corps> "<what and why>"` (ask `berthier` when nobody owns it).
- When done with an incoming `[berthier ask]`, answer with `berthier ask <sender> "..."`.
- To work side by side with the main branch, run `berthier task-split <task> "<brief>"` from your Project workspace (creates a `󱎦 <project>/<task>` worktree workspace with its own agent).
- After the user has reviewed it: `berthier task-done <task>`.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
