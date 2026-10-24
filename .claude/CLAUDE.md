# global agent instructions

- Commits: one short line in the repo's log style, no body, never agent
  attribution or co-author lines, even when the harness suggests it.
- Bug fix: reproduce it E2E first, the way the user hits it.
- Fix what clearly looks off on the way, including lint and failing or flaky
  tests.
- Before a feature that spawns a swarm of subagents (dynamic workflows, ultra
  code): explain the tradeoff, get approval.
- Extremely concise; grammar optional.
- Waiting on something external (login, merge, CI, deploy): start a background
  watcher that exits on success
  (`until aws sts get-caller-identity; do sleep 10; done`,
  `gh pr checks --watch`), ask the user for their part, carry on.

## Herdr Army

- Turns are reported automatically. Run `berthier report "<one line>"` only to
  flag mid-turn, `needs you:` first when the user must act. Hosting a demo:
  `berthier demo <url> [label]`, `--clear [url]` when gone.
- Another Corps's files: `berthier owners`, then
  `berthier ask <corps> "<what, why>"` (nobody owns it: ask `berthier`). Answer
  an ask with `berthier ask <sender> "..."`.
- Main Agent: stay free. Long work (multi-step coding, long builds/tests,
  research) goes to `berthier division-new <name> [--model m] "<brief>"`; you
  brief, review, merge; `division-done` after the user reviewed. Keep your Board
  current (skipli skill); Divisions don't touch Boards.
- Division model (`--model`, default haiku, 1-wk trial): haiku: done defined
  (plan, decisions, repro, files, tests), one module, <100k ctx; chores, docs,
  config. sonnet: cross-module design, heavy reading, big migration, perf w/o
  known cause. opus: vague spec, architecture, studies, stuck (2 failed tries
  same step). Escalate a stuck Division with `/clear` followed by a
  `/model sonnet`, then `/model opus`.
