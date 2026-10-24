---
name: loop-orchestrate
description: Autonomous agent-loop orchestrator for the current repo. Long-polls GitHub for eligible issues, dispatches each to a loop within the user-wide WIP limit, and tracks finished loops. Keeps its own context minimal. Invoke as /loop-orchestrate.
disable-model-invocation: true
model: sonnet
---

# Orchestrate loops

You are a dispatcher. All work happens in loops; your job is to start them and keep tabs.

## Context budget
- Never read issue bodies, PR diffs, comments, `.agents/work/` files, loop logs or friction notes. Event lines and `poll.sh --status` are all you need.
- Keep every reply to one line per event. No summaries between events.

## Setup
1. From the repo root, check `.agents/loop.md` and `.agents/settings.json` exist. If not, stop and suggest `/loop-setup`.
2. Load the `PushNotification` tool (ToolSearch `select:PushNotification`).
3. Run `~/.config/agents/skills/loop-orchestrate/poll.sh --status` and print its line.

## Loop
1. Start `~/.config/agents/skills/loop-orchestrate/poll.sh` with Bash `run_in_background`. It exits as soon as it has events. Wait for its notification; do not poll its output.
2. Handle each output line:
   | Event | Action |
   |---|---|
   | `dispatch <N>` | One Bash call per event with literal values (no `for` loops, `$PWD` or other expansions; a compound command is refused under dontAsk). Start the loop and do not wait: in tmux, `tmux new-window -d -n loop-<N> -c <repo-root> '~/.config/agents/skills/loop-run/loop-run.sh <N>'`; otherwise `setsid -f ~/.config/agents/skills/loop-run/loop-run.sh <N> >/dev/null 2>&1`. |
   | `done <N> human-review` | PushNotification: `#<N> ready for your review: https://github.com/<owner>/<repo>/issues/<N>`. |
   | `done <N> blocked` | PushNotification: `#<N> blocked, needs you: <repo-root>/.agents/work/<N>/blocked.md`. |
   | `done <N> error` | One line. The loop blocks the item itself on a repeated failure. |
   | `stale <N> <slot>` | Run `~/.config/agents/skills/loop-orchestrate/requeue.sh <N> <slot>`. It requeues the item the first time (output `requeued`) and blocks it the second (`blocked`, then notify like `done <N> blocked`). |
   | `idle <k>` | PushNotification: `<k> items blocked, nothing else to do in <repo>`. Keep polling. |
   | `drain` | Print `poll.sh --status`, then stop. |
3. Go back to step 1.

To stop gracefully, the human runs `touch ~/.local/state/agent-loop/drain`; remove it to resume.

Contract, labels and state files: `~/.config/agents/skills/loop-setup/PROTOCOL.md`.
