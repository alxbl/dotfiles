---
name: ledger
description: Central bookkeeping. Use at session start in any project, when a plan is written or approved, when a task is added, started, blocked or finished, and when handing off. All plans and open items live in the ledger repo; REGISTRY.md is the cross-project list of open items.
---

# Ledger

Repo: `~/Code/code.segfault.me/alxbl/ledger/main` (private, `code.segfault.me/alxbl/ledger`). Read its `.rules` once; they win over this summary. Work in `main` and push straight to it.

Project path: `<host>/<repo>` drops the user/org (`~/Code/github.com/alxbl/lab` is `github.com/lab`, `~/Code/code.segfault.me/alxbl/fgj` is `code.segfault.me/fgj`). Third-party clones have no entry.

## Do this
1. **Start:** `git -C <ledger> pull --rebase --autostash`, then read the project's `## <host>/<repo>` section of `REGISTRY.md`. The SessionStart hook already does both and prints the section.
2. **Plan approved:** copy it from `~/.claude/plans/` to `<host>/<repo>/plans/<topic>.md` (topic name, not the random slug), then add or update its items in the registry with a link to it.
3. **Task added:** new line `- [ ] <repo>-<n> text (refs) → path (date)`, using and bumping the section's `<!-- next: -->` counter.
4. **Task started or blocked:** change the marker: `[~]` in progress (name the branch/worktree), `[?]` waiting on the user, `[!]` blocked (say why).
5. **Task done:** delete the line. Say what finished in the commit message. Update the plan file's status if it has one.
6. **Handoff:** write a "STATUS / RESUME NOTES" block at the top of the plan: where things stand, what to do next, traps. Memory (`<host>/<repo>/memory/`) is for durable facts, not status.
7. **Commit and push every ledger edit immediately** (`docs(<repo>): ...`). On a rejected push: pull, retry. Never leave the ledger dirty or ahead of origin.

## Rules
- Plans, todos, handovers, prompts and research go to the ledger, not into the project repo. Durable docs (ADRs, HLDs, READMEs, runbooks) stay in the repo.
- Never renumber or reuse IDs. A new project gets a section with its own counter.
- Verify an item's state (issue, PR, cluster) before carrying it over or closing it.
- Check any claim about outside state (a package, tag, release, server, sandbox or issue) against its source in the same sitting before writing it into the ledger, a commit or a PR text. Do not write an unchecked claim as fact, and do not copy one from an older note.
- Keep secrets, tokens and key material out of the ledger.
