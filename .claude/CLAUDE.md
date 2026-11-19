# global agent instructions

- Commits: one short line in the repo's log style, no body, never agent
  attribution or co-author lines, even when the harness suggests it.
- Bug fix: reproduce it E2E first, the way the user hits it.
- Fix what clearly looks off on the way, including lint and failing or flaky
  tests.
- Before a feature that spawns a swarm of subagents (dynamic workflows, ultra
  code): explain the tradeoff, get approval.
- Waiting on something external (login, merge, CI, deploy): start a background
  watcher that exits on success
  (`until aws sts get-caller-identity; do sleep 10; done`,
  `gh pr checks --watch`), ask the user for their part, carry on.

## Naming

Every name you choose, for files, scripts, directories, functions, variables,
classes, commits, branches, anything, must use precise professional vocabulary.
Choose the word a 1972 IBM engineer would write in a specification. No slang, no
casual shorthand, no cute or clever names, no words borrowed from chat culture.
This applies universally, not only to the one example that follows: a script
that deploys dashboards is deploy_dashboards.sh, not push_dashboards.sh. That is
one illustration of the principle, not the extent of it.
