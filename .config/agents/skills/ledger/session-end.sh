#!/usr/bin/env bash
# SessionEnd hook: commit and push memory changes in the ledger. Touches nothing else.
# Commits unsigned so a locked GPG agent cannot hang the hook.
. "$(dirname "$(readlink -f "$0")")/lib.sh"
[[ -d $LEDGER_ROOT/.git ]] || exit 0
cd "$LEDGER_ROOT" || exit 0
shopt -s nullglob
dirs=(*/*/memory)
((${#dirs[@]})) || exit 0
git add -A -- "${dirs[@]}" >/dev/null 2>&1
git diff --cached --quiet -- "${dirs[@]}" && exit 0
# Commit by file: a pathspec naming an empty, untracked memory dir makes git abort.
mapfile -d '' files < <(git diff --cached --name-only -z -- "${dirs[@]}")
timeout 20 git -c commit.gpgsign=false commit -q -m "chore(memory): sync session memory" -- "${files[@]}" >/dev/null 2>&1 || exit 0
timeout 20 git pull --rebase --autostash -q >/dev/null 2>&1
timeout 20 git push -q >/dev/null 2>&1 || echo "ledger: memory committed but push failed" >&2
exit 0
