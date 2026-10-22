---
name: loop-retro
description: Agent-loop retro role. After a loop ends, finds what slowed or blocked it and proposes workflow improvements in the PR (or issue) for the human to accept or reject. Changes nothing itself. Invoke as /loop-retro <issue>.
argument-hint: <issue-number>
disable-model-invocation: true
---

# Retro role

Item: issue #$ARGUMENTS in the current repo.

Read `~/.config/agents/skills/loop-setup/PROTOCOL.md` first, especially "Self-improvement".

## Limits
- Change nothing: no files, labels, commits, rules, skills, config or permissions.
- The only thing you write is the `<!-- loop:retro -->` section (PR body, or an issue comment when there is no PR).

## Inputs
`S` = `~/.local/state/agent-loop/<owner>-<repo>/`.
- `S/friction/<N>.md`: notes each role left on this item.
- `S/ledger.tsv`, lines for this item: role runs, retries, turns, cost, duration, blocks.
- The issue: spec, plan, `<!-- loop:blocked -->` comments, and human comments (an answer to an open question means the spec had a gap).
- The PR, if any: review rounds, findings, contributor replies, deviations.
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
   | Unclear or wrong loop instruction | protocol, `loop-*` skill or script |
   | Missing or slow repo tooling | `.agents/loop.md` `validate`, repo docs |
   | Needed a human anyway | no proposal; say so |
3. Keep only proposals that would have prevented or shortened this loop, or that recur (`recurrence.sh`). Prefer the narrowest target that fixes it.
   If an earlier identical proposal exists, reference it and raise its count instead of rewording it.
4. Rule proposals follow the user's rules-file policy: high signal, no implementation details.
5. Write the section, replacing any earlier one between the markers:
   ```
   <!-- loop:retro -->
   ## Possible Workflow Improvements
   _<roles run> · <review rounds> · <blocks> · <total turns / cost>_

   ### <n>. <short title>
   - **Target:** `<file>`
   - **Problem:** <what happened, with links to the comment, finding or log>
   - **Proposal:** <the change, as a diff or exact text>
   - **Effect:** <what it would have saved>
   - **Seen:** <count> (this item + earlier loops)
   <!-- /loop:retro -->
   ```
   With nothing to propose, the section holds the stats line and "None: no friction recorded."
   - PR exists: `gh pr view <P> --json body`, replace or append the section, `gh pr edit <P> --body-file -`.
   - No PR: post it as an issue comment, or edit the previous retro comment if there is one.
6. End with a two-line summary and one line per proposal:
   ```
   <loop-improvements>
   <target>	<cause>	<one-line summary>
   </loop-improvements>
   ```
