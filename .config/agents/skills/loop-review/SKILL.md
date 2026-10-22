---
name: loop-review
description: Agent-loop reviewer role. Light rule-compliance check of the PR for a GitHub issue; passes it to the human or asks the contributor for changes. Invoke as /loop-review <issue>.
argument-hint: <issue-number>
disable-model-invocation: true
---

# Review role

Item: issue #$ARGUMENTS in the current repo.

Read `~/.config/agents/skills/loop-setup/PROTOCOL.md` first. It defines labels, formats, blocking and the final message.

This is a compliance check, not a deep code review. The human does the final review.

## Limits
- Read only on the code: never push, approve, merge or close.
- Flag only concrete violations of the checks below, each with `file:line` and the rule it breaks.
- Do not add requirements the spec and rules don't state. Do not nitpick style the rules don't cover.

## Steps
1. Check the issue has `agent:review`. Find the PR: the open PR whose body contains `<!-- loop:pr issue=<N> -->`. No PR → block.
2. Gather: the spec (issue body), `gh pr view <P> --comments`, `gh pr diff <P>`, `gh pr checks <P>`, earlier review comments and the contributor's replies,
   `.agents/loop.md` (including `review.extra`), `CLAUDE.md` and the docs it links, and the user rules.
3. Check:
   - [ ] Every acceptance criterion is met, and the PR shows how it was verified.
   - [ ] Nothing outside the spec's scope changed. Deviations are listed and justified.
   - [ ] Repo rules: `CLAUDE.md`, `.agents/loop.md` notes and `review.extra`.
   - [ ] User rules: tests added, docstrings state purpose only, comments rare and high-signal, simplest change.
   - [ ] Nothing exceeds the environment access in `.agents/loop.md`. No secrets or generated credentials committed.
   - [ ] Commits and PR follow the convention, the PR says `Closes #<N>`, and nothing contains a session ID or session URL.
   - [ ] `validate` commands ran and passed; CI is green if the repo has CI.
   - [ ] Every finding from the previous round is fixed or answered convincingly.
4. Round number `r` = number of earlier `<!-- loop:review` comments on the PR + 1.
   If a finding would repeat unchanged from the previous round after a reasoned reply, do not post it again: block and summarize both positions.
5. Post the inline findings as one review: `gh api repos/{owner}/{repo}/pulls/<P>/reviews --input -` with `{"event": "COMMENT", "body": "", "comments": [{"path", "line", "body"}]}`.
6. Post the summary with `gh pr comment <P> --body-file -`: `<!-- loop:review round=<r> verdict=<pass|changes> -->`, then the checklist.
7. Move the issue: `agent:review` → `agent:human-review` on pass, `agent:review` → `agent:changes` otherwise.

End with a two-line summary and the `<loop-friction>` block.
