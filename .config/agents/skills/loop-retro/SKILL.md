---
name: loop-retro
description: Agent-loop retro role. After a loop ends, finds what slowed or blocked it and proposes workflow improvements in the PR (or issue) for the human to accept or reject. Changes nothing itself. Invoke as /loop-retro <issue>.
argument-hint: <issue-number>
disable-model-invocation: true
---

# Retro role

Item: issue #$ARGUMENTS in the current repo. Its context directory is `D` = `.agents/work/<N>/`.

Read `~/.config/agents/skills/loop-setup/PROTOCOL.md` first, especially "Self-improvement".

## Limits
- Change nothing: no files, labels, commits, rules, skills, config or permissions.
- The only thing you write is `D/retro.md`.

## Inputs
`W` = `.agents/work/`.
- `D/friction.md`: notes each role left on this item.
- `W/ledger.tsv`, lines for this item: role runs, retries, turns, cost, duration, blocks.
- `D/spec.md`, `D/plan.md`, `D/blocked.md`, and `D/notes.md` (an answer to an open question means the spec had a gap).
- `D/review-*.md` and `D/reply-*.md`; the PR body and deviations if there is a PR.
- `~/.config/agents/skills/loop-retro/recurrence.sh`: earlier proposals across all repos, grouped. Run it instead of reading every `improvements.tsv`.
- The current text of anything you propose to change.

## Steps
1. Build the timeline: roles run, retries, review rounds, where it blocked, and turn or cost outliers against this repo's other ledger lines.
2. For every block, retry, review round, refused tool and friction note, find the root cause:
   | Cause | Usual target |
   |---|---|
   | Missing or ambiguous rule | repo `CLAUDE.md`, or `~/.config/agents/rules` if it applies to every repo |
   | Missing permission or access | `.agents/settings.json`, `.agents/loop.md` `environments` |
   | Spec gap the explorer should have caught | `loop-explore` skill |
   | Plan gap the planner should have caught | `loop-plan` skill |
   | Unclear or wrong loop instruction | protocol, `loop-*` skill or script |
   | Missing or slow repo tooling | `.agents/loop.md` `validate`, repo docs |
   | Needed a human anyway | no proposal; say so |
3. Keep only proposals that would have prevented or shortened this loop, or that recur (`recurrence.sh`). Prefer the narrowest target that fixes it.
   If an earlier identical proposal exists, reference it and raise its count instead of rewording it.
4. Rule proposals follow the user's rules-file policy: high signal, no implementation details.
5. Write `D/retro.md`, replacing any earlier one:
   ```
   ## Possible Workflow Improvements
   _<roles run> · <review rounds> · <blocks> · <total turns / cost>_

   ### <n>. <short title>
   - **Target:** `<file>`
   - **Problem:** <what happened, with the file or log it shows in>
   - **Proposal:** <the change, as a diff or exact text>
   - **Effect:** <what it would have saved>
   - **Seen:** <count> (this item + earlier loops)
   ```
   With nothing to propose, the file holds the stats line and "None: no friction recorded."
6. End with a two-line summary and one line per proposal:
   ```
   <loop-improvements>
   <target>	<cause>	<one-line summary>
   </loop-improvements>
   ```
