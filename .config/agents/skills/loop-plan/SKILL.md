---
name: loop-plan
description: Agent-loop plan role. Turns a spec'd GitHub issue into an implementation plan the contributor can follow. Invoke as /loop-plan <issue>.
argument-hint: <issue-number>
disable-model-invocation: true
---

# Plan role

Item: issue #$ARGUMENTS in the current repo. Its context directory is `D` = `.agents/work/<N>/`.

Read `~/.config/agents/skills/loop-setup/PROTOCOL.md` first. It defines labels, formats, blocking and the final message.

## Limits
- Read only on the code. You write only `D/plan.md`.
- Environments: at most `read-only` checks, and only where `.agents/loop.md` grants access.

## Steps
1. Check the issue has `agent:explored`. If not, stop without changes.
2. Read `D/spec.md`, `D/notes.md` if present, `.agents/loop.md`, `CLAUDE.md`, the docs they link, and the user rules.
3. Read the code the spec touches. Confirm the spec's assumptions against it.
   A spec that is wrong, infeasible or has an open question that changes the design → block (protocol).
4. Write `D/plan.md`:
   - **Steps**: ordered, each small enough to commit on its own.
   - **Files**: expected to change or be added, with the reason.
   - **Tests**: what is added or changed, and where.
   - **Validation**: the `validate` commands and any extra check the acceptance criteria need.
   - **Risks**: what could go wrong and how the contributor will notice.
5. Move `agent:explored` → `agent:planned`.
6. End with a two-line summary and the `<loop-friction>` block.
