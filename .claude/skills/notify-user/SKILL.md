---
name: notify-user
description: Alert the user out loud (desktop notification, chime, spoken message) that you need their permission or input. Use right before you stop to wait on them - asking a question, asking to approve an action, or when blocked on something only they can do. Not for routine progress or finishing a task.
---

# notify-user

The user often works away from the terminal. Before waiting on them, run:

```bash
bash ~/.claude/skills/notify-user/speak.sh "<message>"
```

Then ask your question or state what you need as usual.

Write the message to be heard, not read: one short sentence that starts with the project name and says what you need. No paths, code or markdown.

- `dotfiles needs your approval to run home-manager switch`
- `skipli: which database should the API use?`

The script returns at once, plays audio in the background, and does nothing when there is no display or audio (e.g. over SSH). `DRY_RUN=1` prints instead of acting.
