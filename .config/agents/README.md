# agents

Agent configuration shared by every coding agent on this machine.

| Path | What |
|---|---|
| `rules` | User-wide agent rules. `~/.claude/CLAUDE.md` links here. |
| `loop.md` | User-wide settings for the agent loop. |
| `skills/loop-*` | The agent loop skillset. `~/.claude/skills/loop-*` link here. |
| `tests/` | Tests for the loop scripts, and the test plan. |

## Agent loop

An autonomous pipeline that takes GitHub issues from a goal statement to a reviewed PR. A human decides what goes in (a label) and what ships (the merge); agents do the rest.

```
 human                 loop (one agent at a time)                                                         human
───────            ────────────────────────────────────────────────────────────────────────────────    ─────────
agent:explore ─► explore ─► agent:explored ─► plan ─► agent:planned ─► contribute ─► agent:review ─► review ─► agent:human-review ─► merge
                    │                                                      ▲                         │
                    │                                                      └──── agent:changes ◄─────┘  (max 3 rounds)
                    └─────────────────────────► agent:blocked ◄── any step                              then: retro
```

GitHub carries only the labels and the PR. Specs, plans, reviews, blocks and logs stay on this machine in `.agents/work/` in the repo (git-ignored).

The full contract (labels, formats, config keys, state files) is [`skills/loop-setup/PROTOCOL.md`](skills/loop-setup/PROTOCOL.md). This README covers using it.

### Pieces

| Skill | Kind | Job |
|---|---|---|
| `/loop-setup` | interactive | Enroll a repo: labels, `.agents/loop.md`, `.agents/settings.json`, opened as a PR. |
| `/loop-orchestrate` | long-running agent, sonnet | Polls for eligible issues, starts loops within the WIP limit, notifies you of results. |
| `/loop-run [issue]` | script | One pipeline: slot, claim, roles in order, retro, release. |
| `loop-explore` | role, opus | Turns the goal into a high-level spec with a feasibility analysis. |
| `loop-plan` | role, opus | Turns the spec into an implementation plan. |
| `loop-contribute` | role, sonnet | Implements the plan, tests, opens the PR; fixes review findings. |
| `loop-review` | role, sonnet | Light rule-compliance check; passes to you or asks for changes. |
| `loop-retro` | role, opus | Proposes workflow improvements. Changes nothing. |

Roles run as fresh headless `claude -p` sessions, so each starts with a clean context and the reviewer never shares the contributor's reasoning. The model per role is `model_<role>` in `loop.md`.

### Setup

Once per machine:
```sh
cd ~/.claude/skills && for s in ~/.config/agents/skills/loop-*; do ln -sfn "$s" "${s:t}"; done
```
Needs `gh` (authenticated), `jq`, `flock`, `git`, and `claude`. tmux is optional; loops get their own windows when it is present.

Once per repo, from inside it: `/loop-setup`. It drafts two files for you to approve:
- `.agents/loop.md`: base branch, commit convention, `validate` commands, environments and their access level (`none`, `read-only`, `write`), extra review checks, and links to the repo's workflow docs.
- `.agents/settings.json`: the tool permissions loops run with. It applies to loops only, not to your interactive sessions.

A repo without both files is ignored by every loop script.

### Use

1. Label an issue `agent:explore`. Nothing enters the loop without this.
2. Run the loop:
   - **Supervised:** `/loop-run 59` runs one issue to completion. Or run the roles by hand: `/loop-explore 59`, `/loop-plan 59`, `/loop-contribute 59`, `/loop-review 59`.
   - **Autonomous:** `/loop-orchestrate` in its own tmux pane. It stays idle (no tokens) until there is work.
3. Act on what comes back:
   - `agent:human-review`: review the PR, merge it, or label the issue `agent:changes` with comments to send it back.
   - `agent:blocked`: `.agents/work/<N>/blocked.md` says what is needed and which label to set to resume. Put your answer in `.agents/work/<N>/notes.md`; every role reads it.
   - `.agents/work/<N>/retro.md`: accept or ignore each workflow proposal, separately from the PR itself.

Stop gracefully: `touch ~/.local/state/agent-loop/drain`. Running loops finish, nothing new starts, the orchestrator exits. Remove the file to resume.

Status at a glance: `~/.config/agents/skills/loop-orchestrate/poll.sh --status` from inside the repo.

### Limits and safety

- **WIP**: `wip` in `loop.md` caps concurrent loops across all repos, and so the number of agents working at once. A repo may lower it, never raise it.
- **No merges**: no role merges, closes, deletes or force-pushes. All roles act as your GitHub account, so reviews are comments, not approvals.
- **Permissions**: roles run with `--permission-mode dontAsk`. Anything not allowed by `.agents/settings.json` is refused, and a refusal the task needs blocks the item. Every role may write `.agents/work/`; only contribute may write `.worktrees/`.
- **Environments**: production should be `read-only` or `none`. Pattern-based permission rules are a soft guard; for real enforcement, give the loop read-only credentials (e.g. a read-only kubeconfig) and name them in the environment's `how`.
- **Review rounds**: after 3 rounds asking for changes, or a finding repeated unchanged, the item blocks for you.

### Self-improvement

Every role ends by noting its friction: blocks, refused tools, missing or stale docs, ambiguous rules, spec gaps, rework. After each loop, the retro traces that friction, the review rounds and the blocks to a cause and a target file (repo `CLAUDE.md`, `rules`, the protocol, a skill, `.agents/*`), and writes concrete proposals into `.agents/work/<N>/retro.md`.

Proposals are logged per repo in `.agents/work/improvements.tsv`. `skills/loop-retro/recurrence.sh` groups them across repos, so a problem that keeps coming back shows a rising count. Nothing is ever applied automatically.

### State and debugging

Per-repo context is in `<repo>/.agents/work/`; slot locks and the list of enrolled repos are in `~/.local/state/agent-loop/`.

| File (in `.agents/work/`) | Use |
|---|---|
| `ledger.tsv` | Every claim, role run (exit code, turns, cost, seconds), block, dispatch and result |
| `<N>/logs/` | Raw JSON output of each role run; start here when a role misbehaves |
| `<N>/friction.md` | Friction notes per issue |
| `improvements.tsv` | Every retro proposal |

Slot locks (`slot-<n>.lock`) are released by the OS when a loop dies. An issue left with `agent:wip` and no live loop shows up as `stale` in the orchestrator, which requeues it once.

### Known limitations
- Single machine: slot locks are local `flock`s.
- GitHub issues only.
- Permission patterns are best-effort; see "Environments" above.

### Development

```sh
~/.config/agents/tests/run.sh            # all tests
~/.config/agents/tests/run.sh test_poll_drain
```
The tests use fake `gh` and `claude` from `tests/stubs/`; they touch no network. [`tests/TESTPLAN.md`](tests/TESTPLAN.md) covers everything beyond them.
