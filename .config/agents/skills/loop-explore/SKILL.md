---
name: loop-explore
description: Agent-loop explore role. Turns a GitHub issue's goal statement into a high-level spec with a feasibility analysis. Invoke as /loop-explore <issue>.
argument-hint: <issue-number>
disable-model-invocation: true
---

# Explore role

Item: issue #$ARGUMENTS in the current repo.

Read `~/.config/agents/skills/loop-setup/PROTOCOL.md` first. It defines labels, formats, blocking and the final message.

## Limits
- Read only. No edits to the repo, no branches, no commits.
- Environments: at most `read-only` checks, and only where `.agents/loop.md` grants access.

## Steps
1. Check the issue has `agent:explore`. If not, stop without changes.
2. Read the issue and its comments (`gh issue view <N> --comments`), linked issues and PRs, `.agents/loop.md`, `CLAUDE.md`, and the docs they link.
   If the body already has a `<!-- loop:spec -->`, refine it: comments since then may answer its open questions.
3. Research the current state: the code paths involved, git history (`git log -S`, `git blame`), upstream docs and release notes, related issues.
4. Assess feasibility. Test the key assumptions with cheap read-only checks instead of trusting them.
   Name the hurdles: version constraints, upstream bugs, missing access, data or migration risk, conflicts with repo rules.
5. Write the spec into the issue body with `gh issue edit <N> --body-file -` and a heredoc, using the protocol's spec format.
   - Goal: the original text, verbatim.
   - Proposed solution: components, interfaces, behaviour and data flow, plus rejected alternatives and why.
     Enough that the contributor can plan without redoing your research. Not a list of file edits.
   - Acceptance criteria: observable results a reviewer can check from the diff and validation output.
   - Rules & environments in scope: the `CLAUDE.md` rules and environments the change touches, and the access each needs.
6. Decide:
   - Infeasible as stated, an open question that changes the solution, or a step that needs consent → block (protocol).
   - Otherwise move `agent:explore` → `agent:explored`.
7. End with a two-line summary and the `<loop-friction>` block.
