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
