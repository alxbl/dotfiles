---
# Agent loop settings for this repo. Contract: ~/.config/agents/skills/loop-setup/PROTOCOL.md
base: main
branch: "<type>/<slug>"
commits: conventional
# max_review_rounds: 3
# model_<role>: opus|sonnet   # override the user-wide model for explore, plan, contribute, review or retro
# wip: 1            # may only lower the user-wide limit
validate:
  - <command that must pass before pushing>
environments:
  <name>:
    access: none    # none | read-only | write
    how: <how to target it, e.g. which kubeconfig or credentials>
    # allow: [<commands allowed at write access>]
    # ask: [<commands that always need a human>]
review:
  extra:
    - <repo invariant a reviewer can check from the diff>
---
# Workflow notes

Links to the docs that define how work is done here (development guide, test setup).
Anything a loop must know that `CLAUDE.md` does not already say.
