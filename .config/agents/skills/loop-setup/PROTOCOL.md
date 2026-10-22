# Agent Loop Protocol

The shared contract for the `loop-*` skills and scripts. Every role reads this file before acting.
If a skill and this file disagree, this file wins.

## Terms
- **Item**: a GitHub issue in the repo the loop runs in.
- **Role**: `explore`, `contribute`, `review` or `retro`. Each role run is a fresh headless agent.
- **Loop**: one run of `loop-run.sh`. It carries one item through the roles, one agent at a time.
- **Slot**: a lock a loop holds while it runs. The number of slots is the WIP limit.
- **Round**: one review of a PR, ending with verdict `pass` or `changes`.
- **Owner**: the repo owner. Block comments mention them.

## Components
| Component | Kind | Job |
|---|---|---|
| `loop-orchestrate` | skill + `poll.sh` | Watches for work, dispatches loops, records results, notifies the human. |
| `loop-run` | skill + `loop-run.sh` | One pipeline: slot, claim, roles in order, retro, release. No LLM. |
| `loop-explore` | role skill | Goal → spec. |
| `loop-contribute` | role skill | Plan, implement, open the PR, fix review findings. |
| `loop-review` | role skill | Light rule-compliance review. |
| `loop-retro` | role skill | Finds what slowed or blocked the loop; proposes workflow improvements. |
| `loop-setup` | skill | Enrolls a repo: labels, `.agents/loop.md`, `.agents/settings.json`. |

## Configuration
Settings resolve in this order, later entries winning:
1. Defaults below.
2. User-wide `~/.config/agents/loop.md` (YAML front matter).
3. Repo `.agents/loop.md` (YAML front matter, then free-form workflow notes).

| Key | Default | Scope | Meaning |
|---|---|---|---|
| `wip` | `1` | user | Max concurrent loops on this machine. A repo may set a lower value, never higher. |
| `max_review_rounds` | `3` | user, repo | Rounds with verdict `changes` before a human must step in. |
| `poll_interval` | `60` | user | Seconds between orchestrator polls. |
| `base` | repo default branch | repo | Branch PRs target. |
| `branch` | `<type>/<slug>` | repo | Branch name pattern. `<type>` is the conventional-commit type. |
| `commits` | `conventional` | repo | Commit message convention. |
| `validate` | `[]` | repo | Commands the contributor must run and pass before pushing. |
| `environments` | `{}` | repo | Named environments and their access level. |
| `review.extra` | `[]` | repo | Extra checklist items for the reviewer. |

A repo is enrolled when it has both `.agents/loop.md` and `.agents/settings.json`. Scripts refuse other repos.

The free-form part of `.agents/loop.md`, the repo's `CLAUDE.md`, and the docs they link to are binding for every role.

## Environments
Each entry under `environments` has an `access` level, a `how` note, and optional `allow` / `ask` lists.

| Access | Allowed |
|---|---|
| `none` (default) | Nothing. Do not connect, query, or read state. |
| `read-only` | Commands that only read state (`get`, `describe`, `logs`, `plan`, `status`). |
| `write` | Commands in `allow`. Anything in `ask` or not listed blocks the item. |

An environment not listed has access `none`. Never exceed the listed access, even when a tool permission would allow it.

## Permissions
Roles run as `claude -p "/loop-<role> <N>" --permission-mode dontAsk --settings .agents/settings.json`.
Only tools allowed by the merged settings run; anything else is refused, never prompted.
Every role except `contribute` also runs with Edit and Write disabled.
`.agents/settings.json` holds the loop's allow and deny rules and must match `environments`. It applies to loops only, not to interactive sessions.
If the task needs a refused tool, block the item and name the tool. Do not work around a refusal.

## Labels
All state lives on the issue.

| Label | Meaning | Set by |
|---|---|---|
| `agent:explore` | Approved for the loop, needs a spec. | human |
| `agent:explored` | Spec ready, needs implementation. | explore |
| `agent:review` | PR open, awaiting review. | contribute |
| `agent:changes` | Review asked for changes. | review, or human |
| `agent:human-review` | Reviewer satisfied; human reviews and merges. | review |
| `agent:blocked` | Needs a human. No loop picks it up. | any role, loop-run, orchestrator |
| `agent:wip` | A loop holds the item. | loop-run only |
| `loop:<n>` | Held by slot `<n>`. | loop-run only |

An item carries exactly one state label (the first six). A role moves it in a single `gh issue edit` with `--remove-label` and `--add-label`.
Roles never touch `agent:wip` or `loop:<n>`.

## Flow
```
agent:explore ─explore─► agent:explored ─contribute─► agent:review ─review─► agent:human-review ─► human merges
                                                         ▲               │
                                                         └─contribute── agent:changes
any step ─► agent:blocked                       after every loop: retro
```

### Eligibility and priority
An item is eligible if it is open, has neither `agent:wip` nor `agent:blocked`, and has one of these labels. Oldest first within each group:
1. `agent:changes`
2. `agent:review`
3. `agent:explored`
4. `agent:explore`

### Loop
`loop-run.sh` takes a slot, claims the item (`agent:wip`, `loop:<n>`, comment `loop:<n> claimed`), then repeats:
read the state label, run the matching role, check the label moved. It stops at `agent:human-review` or `agent:blocked`, runs the retro, and releases the item.
- A role run that leaves the label unchanged has failed. It is retried once; a second failure blocks the item.
- Before a contributor fixes review findings, the loop counts `changes` rounds since the last `pass` or block. At `max_review_rounds` it blocks the item.
- A human resumes a blocked item by removing `agent:blocked` and setting a state label. Rounds count again from zero.

### Blocking
To block, a role moves its state label to `agent:blocked` and posts one comment:
```
<!-- loop:blocked -->
@<owner> <role> blocked this item.
**Needed:** decision, consent, access, or fix, stated so the owner can act on it.
**Tried:** what was checked or attempted.
**Resume:** which label to set once resolved.
```
Block instead of guessing when:
- a question changes the solution
- a step needs more access than the environment grants, or a refused tool
- a step needs consent the repo rules require
- validation fails for a cause outside the item's scope
- the spec turns out wrong or infeasible
- a review finding repeats unchanged from the previous round

## Handoff formats
Roles find each other's output through HTML comment markers. Scripts count markers instead of parsing text.

### Spec (issue body, written by explore)
```
<!-- loop:spec -->
## Goal
<original issue text, verbatim>
## Background
## Proposed solution
## Feasibility & hurdles
## Out of scope
## Acceptance criteria
- [ ] ...
## Rules & environments in scope
## Open questions
```
A high-level solution, not an implementation plan. A rewrite keeps the Goal section verbatim.

### Plan (issue comment, written by contribute before coding)
`<!-- loop:plan -->` followed by the steps, the files expected to change, and the validation to run.

### PR body (written by contribute)
```
<!-- loop:pr issue=<N> -->
Closes #<N>
## Summary
## Acceptance criteria
- [x] <criterion>: <how it was verified>
## Validation
<commands run and their result>
## Deviations from the spec
```
The retro appends its section after these. Other roles never edit it.

### Review (PR comment, written by review)
```
<!-- loop:review round=<r> verdict=<pass|changes> -->
- [x] / [ ] <check>: <finding>
```
Inline findings go in one review with event `COMMENT`. All roles act as the same GitHub account, so reviews are comments, never approvals or change requests.

### Fix reply (written by contribute)
Each finding is answered in its thread: what changed, or why no change is needed. Fix commits go on the same branch.

### Final message (every role)
A role's last message ends with its friction notes, one per line, tags on their own lines:
```
<loop-friction>
- <kind>: <what happened> (<evidence: link, file:line, command>)
</loop-friction>
```
`kind` is one of `blocked`, `refused-tool`, `missing-access`, `missing-doc`, `stale-doc`, `ambiguous-rule`, `spec-gap`, `rework`, `slow-validation`, `other`.
Record anything that cost time, needed a guess, or would trip the next loop. Leave the block empty when nothing did. `loop-run.sh` stores the notes for the retro.

## Self-improvement
Nothing in the loop changes its own rules, skills, protocol, config or permissions. Improvements are proposals; the human decides what goes in, separately from the item's PR.

After every loop, `loop-retro` reads the item's history (friction notes, ledger metrics, block comments, review rounds, human comments) and the earlier proposals, then writes:
```
<!-- loop:retro -->
## Possible Workflow Improvements
<!-- /loop:retro -->
```
into the PR body, or as an issue comment when there is no PR. Proposals may target the repo's `CLAUDE.md`, `.agents/loop.md`, `.agents/settings.json`, the user rules (`~/.config/agents/rules`), this protocol, or the `loop-*` skills and scripts.
Its final message lists each proposal for `improvements.tsv`, so later retros can spot recurring problems:
```
<loop-improvements>
<target>	<kind>	<one-line summary>
</loop-improvements>
```

## Git
- Work only in a worktree at `.worktrees/<branch>` (add `.worktrees/` to `.git/info/exclude`). Never edit the main checkout.
- Branch from an up-to-date `base`. Never force-push; add commits.
- Follow the repo's commit convention. Never put a session ID or session URL in commits or PR bodies.
- Never merge, close, or delete a PR, issue, or branch.

## Local state
Everything lives in `~/.local/state/agent-loop/`. Locks work on one machine only.

| Path | Writer | Content |
|---|---|---|
| `slot-<n>.lock` | loop-run | `flock` target, one per slot `1..wip` |
| `slot-<n>.item` | loop-run | `<owner>/<repo>#<N>` while held |
| `claim.lock` | loop-run | Serializes picking and claiming |
| `drain` | human | If present, no new dispatches |
| `<owner>-<repo>/ledger.tsv` | loop-run, poll | `time  item  slot  event  detail`, including per-role turns, cost, duration |
| `<owner>-<repo>/results/` | loop-run → poll | One file per finished loop: `<N> <slot> <result>` |
| `<owner>-<repo>/pending/` | poll | Dispatched items whose loop has not taken a slot yet |
| `<owner>-<repo>/logs/` | loop-run | Raw JSON output of every role run |
| `<owner>-<repo>/friction/<N>.md` | loop-run | Friction notes per item, by role |
| `<owner>-<repo>/improvements.tsv` | loop-run | `time  item  target  kind  summary`, from retros |

## Exit codes (`loop-run.sh`)
| Code | Meaning |
|---|---|
| `0` | Item reached `agent:human-review` |
| `2` | Item blocked |
| `3` | Not started: not enrolled, no free slot, or item not eligible |
| `1` | Error |
