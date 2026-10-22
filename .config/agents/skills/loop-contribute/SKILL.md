---
name: loop-contribute
description: Agent-loop contributor role. Plans and implements a spec'd GitHub issue and opens a PR, or fixes review findings on its PR. Invoke as /loop-contribute <issue>.
argument-hint: <issue-number>
disable-model-invocation: true
---

# Contribute role

Item: issue #$ARGUMENTS in the current repo.

Read `~/.config/agents/skills/loop-setup/PROTOCOL.md` first. It defines labels, formats, blocking, git rules and the final message.

The issue's label picks the mode: `agent:explored` → **Implement**, `agent:changes` → **Fix**. Any other label: stop without changes.

## Rules for both modes
- Follow `.agents/loop.md`, `CLAUDE.md`, the docs they link, and the user rules.
- Make the simplest change that meets the acceptance criteria. Stay out of the spec's "Out of scope".
- Add unit tests for the change. If the repo has none for this area, run the closest check in `validate` and say so in the PR.
- Environments: only the access `.agents/loop.md` grants. Never run a command listed under `ask`.
- If the spec is wrong or infeasible, block with what you found. Small, justified deviations are fine; list them in the PR.
- Never edit the `<!-- loop:retro -->` section of the PR body.

## Implement
1. Read the spec (issue body) and comments.
2. Create the worktree: `git fetch origin <base>`, then `git worktree add .worktrees/<branch> -b <branch> origin/<base>`.
   Name the branch from `.agents/loop.md` `branch`. Make sure `.worktrees/` is in `.git/info/exclude`.
3. Post the plan as an issue comment (`<!-- loop:plan -->`): steps, files expected to change, tests, validation.
4. Implement and test inside the worktree.
5. Run every `validate` command and the relevant tests. All must pass. A failure caused outside the item's scope → block.
6. Commit using the repo's convention, then `git push -u origin <branch>`.
7. Open the PR: `gh pr create --base <base> --head <branch> --title "<conventional title>" --body-file -`, using the protocol's PR body format.
8. Move `agent:explored` → `agent:review`.

## Fix
1. Find the PR: the open PR whose body contains `<!-- loop:pr issue=<N> -->`.
2. Read the latest `<!-- loop:review ... -->` comment, its inline findings (`gh api repos/{owner}/{repo}/pulls/<P>/comments`), and any human comments since your last push.
3. Use the existing worktree. If it is missing: `git fetch origin <branch>`, then `git worktree add .worktrees/<branch> <branch>`.
4. Address each finding. Reply in its thread (`gh api repos/{owner}/{repo}/pulls/<P>/comments/<id>/replies -f body=...`) with what changed.
   If you disagree, reply with your reasoning and leave the code alone; the reviewer decides or escalates.
5. Validate as in Implement step 5. Commit and push (never force).
6. Update the PR body's acceptance criteria, validation and deviations if they changed.
7. Move `agent:changes` → `agent:review`.

End with a two-line summary and the `<loop-friction>` block.
