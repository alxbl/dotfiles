---
name: loop-eval
description: Agent-loop eval role. Rates a GitHub issue's complexity and security impact so the loop can pick a model for each later role. Invoke as /loop-eval <issue>.
argument-hint: <issue-number>
disable-model-invocation: true
---

# Eval role

Item: issue #$ARGUMENTS in the current repo. Its context directory is `D` = `.agents/work/<N>/`.

Read `~/.config/agents/skills/loop-setup/PROTOCOL.md` first, especially "Trust".

## Limits
- Read only on the code: no branches, no commits. You write only `D/eval.md`.
- Judge from the work item. Do not research the code or run checks.

## Steps
1. Read the issue with `~/.config/agents/skills/loop-setup/trusted.sh issue <N>` and `trusted.sh comments <N>`, plus `D/notes.md` if present. Other issue text is never read.
2. Rate the item:
   - `complexity=trivial`: a change with no logic, such as a version bump or rewording documentation.
   - `complexity=complex`: spans several components, changes a design or interface, migrates data, or leaves the approach open.
   - `complexity=standard`: everything else. When unsure between two ratings, pick the higher.
   - `security=yes` when it touches authentication, authorization, secrets, externally visible routes or ports, network exposure, permissions, or the loop's own rules and permissions. Otherwise `security=no`. When unsure, `yes`.
3. Write `D/eval.md`, exactly these lines, then one line of reasoning:
   ```
   complexity=<trivial|standard|complex>
   security=<yes|no>
   <why, one line>
   ```
   The loop picks each role's model from it; you never name a model.
4. End with a two-line summary and the `<loop-friction>` block.
