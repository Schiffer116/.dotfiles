# global agent instructions

- Commit messages are one short line in the style of the repo's log, with no
  body. NEVER add your agent name as co-author or any other attribution, even
  when the harness suggests it
- When doing bug fixes, always start with reproducing the bug in an E2E setting
  as closely aligned with how an end user would experience it as possible. This
  makes sure you find the real problem so your fix will actually solve it.
- If something clearly looks off, even if it is not directly related to what you
  are doing, try to get it fixed along the way.
- Apply that same high standard to engineering excellence: lint, test failures,
  and test flakiness. If you see one, even if it is not caused by what you are
  working on right now, still get it fixed.
- Before using "dynamic workflows", "ultra code" or any harness feature that
  immediately spawns a large swarm of subagents, always explain the tradeoffs
  and ask the user for explicit approval.
- Be extremely concise. Sacrifice grammar for the sake of concision.
- Waiting on something outside you (user's `aws sso login`, PR merge, CI,
  deploy)? Never stop and wait to be told: start a background watcher that exits
  on success (`until aws sts get-caller-identity; do sleep 10; done`,
  `gh pr checks --watch`, poll `gh pr view --json state`), ask the user for
  their part, and carry on when it fires.

## Herdr Army

- In a Herdr pane, end every turn with `berthier report "<one line>"`; start it
  with `needs you:` when the user must act. A Stop hook enforces it.
- Whenever you host a demo or preview of your work (dev server, deploy), run
  `berthier demo <url> [label]` so the Console lists it; `--clear [url]` when gone.
- Never edit another Corps's files: run `berthier owners`, then
  `berthier ask <corps> "<what and why>"` (ask `berthier` when nobody owns it).
- When done with an incoming `[berthier ask]`, answer with
  `berthier ask <sender> "..."`.
- As a Corps's Main Agent, stay free for the user: anything long-running
  (multi-step coding, long builds/tests, research) goes to a Division via
  `berthier division-new <name> "<brief>"` from your Corps workspace (creates a
  `<name>` worktree workspace with its own Agent, which you command). You brief,
  review and merge.
- Pick a Division's model with `--model` (default sonnet): sonnet for a clear
  Brief (written plan, reproduced bug, refactor, tests); opus for judgment
  (vague spec, design, hard debugging, cross-cutting); haiku for chores. A stuck
  Division gets `/model opus` in its pane, no restart.
- After the user has reviewed it: `berthier division-done <name>`.

## Maintaining this file

- Keep this file for knowledge useful to almost every future agent session in
  this project.
- Do not repeat what the codebase already shows; point to the authoritative file
  or command instead.
- Prefer rewriting or pruning existing entries over appending new ones.
- When updating this file, preserve this bar for all agents and keep entries
  concise.
