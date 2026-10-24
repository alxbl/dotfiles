---
name: loop-setup
description: Enroll the current repo in the agent loop. Creates the labels and drafts .agents/loop.md and .agents/settings.json from the repo's own rules and docs, for the user to approve. Invoke as /loop-setup.
disable-model-invocation: true
---

# Enroll a repo

Interactive: the user approves every file before it is committed. Read `PROTOCOL.md` in this directory first.

1. **User config.** If `~/.config/agents/loop.md` is missing, copy the defaults from the protocol's configuration table and tell the user.
2. **Labels.** Run `~/.config/agents/skills/loop-setup/labels.sh` from the repo root. It is idempotent.
   Loop context stays local: `loop-run.sh` adds `.agents/work/` and `.worktrees/` to `.git/info/exclude` itself on its first run, so there is nothing to do here.
3. **Research the repo:** `CLAUDE.md` and the docs it links, `README`, CI workflows, test and lint commands, recent `git log` (commit and branch conventions), and the default branch.
4. **Draft `.agents/loop.md`** from `config-template.md`:
   - `validate`: commands that already exist in the repo and pass on the default branch. Run each once to check.
   - `environments`: one entry per environment the rules or docs name. Default every entry to `none`.
     Ask the user for each environment's access level with AskUserQuestion; recommend `read-only` for production and say why.
   - `review.extra`: invariants from `CLAUDE.md` a reviewer can check from a diff (kept-in-sync files, pinned versions, forbidden files).
   - Free-form part: links to the docs that define the workflow. Do not copy rules out of `CLAUDE.md`.
5. **Draft `.agents/settings.json`** from `settings-template.json`:
   - Add allow rules for the `validate` commands and for each environment at its access level.
   - For `read-only` environments, allow only the read verbs, with the environment pinned in the pattern (e.g. its kubeconfig), and deny the write verbs.
   - Tell the user pattern rules are best-effort, and recommend real enforcement for production: read-only credentials (a read-only kubeconfig or RBAC role, a read-only token) referenced in `how`.
6. **Show both drafts** to the user and apply their changes.
7. **Commit** on a branch `chore/agent-loop`, push, and open a PR. Never commit to the default branch.
8. **Explain how to start:** label an issue `agent:explore`, then run `/loop-run` once supervised, or `/loop-orchestrate`.
