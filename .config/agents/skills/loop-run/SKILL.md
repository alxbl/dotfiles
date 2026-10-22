---
name: loop-run
description: Run one agent loop in the current repo. Takes a WIP slot, claims an issue (the given one or the next eligible), runs explore/contribute/review until it needs a human, then the retro. Invoke as /loop-run [issue].
argument-hint: "[issue-number]"
disable-model-invocation: true
---

# Run one loop

The loop is a script; do not play the roles yourself.

1. From the repo root, run `~/.config/agents/skills/loop-run/loop-run.sh $ARGUMENTS`.
   It blocks until the loop ends, which can take a long time. If in tmux, run it in a new window named `loop-<issue or next>` and wait for it to exit.
2. Report the exit code meaning in one line (see `~/.config/agents/skills/loop-setup/PROTOCOL.md`, "Exit codes") and link the issue.
   On `0` or `2`, add the PR or block comment link. Do not read the logs unless asked.

Contract, labels and state files: `~/.config/agents/skills/loop-setup/PROTOCOL.md`.
