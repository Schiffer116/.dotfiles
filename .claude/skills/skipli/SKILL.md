---
name: skipli
description: Read or change Skipli boards (cards and tasks) from the terminal with skipli-cli. Use when asked to look at, add to, move, or finish items on a Skipli board.
---

# Skipli boards

Use `skipli-cli` to read and change Skipli boards as the user's account.

1. Run `skipli-cli help` first (and `skipli-cli help <command>`); it lists every command and flag.
2. `skipli-cli boards`, then `skipli-cli board <id>` to see cards and tasks with their ids. Ids only, never names; any unique prefix of an id works.
3. Production by default; `--env dev` for Development. For Army work (Corps Boards), `--env dev` is the default for now.

Signing in is the user's job. If a command says "not signed in" or "signed out", ask the user to run `skipli-cli login <email>` in their own terminal (add `--env dev` if needed); with `!` there is no terminal to type the code into, so they finish with `! skipli-cli login --code <code>`. Never sign in as the user's account yourself, and never read their stored session.

Not available by design: deleting or renaming boards, invitations, roles, profile.
