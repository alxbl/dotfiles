---
name: loop-contribute
description: Agent-loop contributor role. Implements a planned GitHub issue and opens a PR, or fixes review findings on its PR. Invoke as /loop-contribute <issue>.
argument-hint: <issue-number>
disable-model-invocation: true
---

# Contribute role

Item: issue #$ARGUMENTS in the current repo. Its context directory is `D` = `.agents/work/<N>/`.

Read `~/.config/agents/skills/loop-setup/PROTOCOL.md` first. It defines labels, formats, blocking, git rules and the final message.

The issue's label picks the mode: `agent:planned` → **Implement**, `agent:changes` → **Fix**. Any other label: stop without changes.

## Rules for both modes
- Follow `.agents/loop.md`, `CLAUDE.md`, the docs they link, and the user rules.
- Make the simplest change that meets the acceptance criteria. Stay out of the spec's "Out of scope".
- Add unit tests for the change. If the repo has none for this area, run the closest check in `validate` and say so in the PR.
- Environments: only the access `.agents/loop.md` grants. Never run a command listed under `ask`.
- If the spec is wrong or infeasible, block with what you found. Small, justified deviations are fine; list them in the PR.
- Write code only in the worktree. Context files in `D` are for reading, except the ones named below. Before the first `cd`, run `git rev-parse --show-toplevel` and use the absolute `D` for every later read and write.

## Implement
1. Read `D/spec.md`, `D/plan.md` and `D/notes.md` if present.
2. Create the worktree: `git fetch origin <base>`, then `git worktree add .worktrees/<branch> -b <branch> origin/<base>`.
   Name the branch from `.agents/loop.md` `branch`. Make sure `.worktrees/` is in `.git/info/exclude`.
3. Follow the plan. Deviate only for a reason you can state, and list each deviation in the PR.
4. Implement and test inside the worktree.
5. Run every `validate` command and the relevant tests from inside the worktree (`cd` into it; the commands assume the repo root). All must pass. A failure caused outside the item's scope → block.
6. Commit using the repo's convention, then `git push -u origin <branch>`.
7. Write the PR body to `D/pr-body.md` in the protocol's PR body format, then open the PR: `gh pr create --base <base> --head <branch> --title "<conventional title>" --body-file D/pr-body.md`. Never pass the body inline.
8. Write the PR number to `D/pr`.
9. Move `agent:planned` → `agent:review`.

## Fix
1. The PR number is in `D/pr`.
2. Read the latest `D/review-<r>.md` and any human comments on the PR or in `D/notes.md` since your last push.
3. Use the existing worktree. If it is missing: `git fetch origin <branch>`, then `git worktree add .worktrees/<branch> <branch>`.
4. Address each finding. Answer every one in `D/reply-<r>.md` with what changed.
   If you disagree, give your reasoning and leave the code alone; the reviewer decides or escalates.
5. Validate as in Implement step 5. Commit and push (never force).
6. If the acceptance criteria, validation or deviations changed, update `D/pr-body.md` and run `gh pr edit <P> --body-file D/pr-body.md`.
7. Move `agent:changes` → `agent:review`.

End with a two-line summary and the `<loop-friction>` block.
