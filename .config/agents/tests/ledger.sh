#!/usr/bin/env bash
# Unit tests for the ledger skill scripts. Temp dirs only; no network.
# Usage: tests/ledger.sh [test-name...]
set -uo pipefail
TESTS=$(dirname "$(readlink -f "$0")")
L=$TESTS/../skills/ledger
PASS=0 FAIL=0

setup() {
  T=$(mktemp -d)
  export HOME=$T/home LEDGER_CODE=$T/Code LEDGER_ROOT=$T/ledger CLAUDE_PROJECTS=$T/claude
  mkdir -p "$HOME" "$LEDGER_CODE/github.com/alxbl/lab/main/src" "$LEDGER_CODE/github.com/other/x" "$CLAUDE_PROJECTS"
  git init -q --bare "$T/origin.git"
  git clone -q "$T/origin.git" "$LEDGER_ROOT" 2>/dev/null
  git -C "$LEDGER_ROOT" config user.email t@t; git -C "$LEDGER_ROOT" config user.name t
  git -C "$LEDGER_ROOT" config commit.gpgsign false
  cat >"$LEDGER_ROOT/REGISTRY.md" <<'R'
# Registry

## github.com/lab
<!-- next: lab-3 -->
- [ ] lab-1 first
- [?] lab-2 second

## github.com/aur
<!-- next: aur-2 -->
- [ ] aur-1 other
R
  git -C "$LEDGER_ROOT" add -A && git -C "$LEDGER_ROOT" commit -qm init && git -C "$LEDGER_ROOT" push -q origin HEAD 2>/dev/null
  cd "$T" || exit 1
}
teardown() { cd / && rm -rf "$T"; }

check() { if "${@:2}"; then return 0; fi; echo "    FAIL: $1"; FAILED=1; }
eq() { [[ $1 == "$2" ]] || { echo "    expected [$2] got [$1]"; return 1; }; }
lib() { ( source "$L/lib.sh"; "$@" ); }
start() { # start CWD: run the SessionStart hook and print its additionalContext
  jq -nc --arg c "$1" '{cwd:$c}' | "$L/session-start.sh" | jq -r '.hookSpecificOutput.additionalContext'
}

test_project_maps_repo_and_worktrees() {
  check "repo" eq "$(lib ledger_project "$LEDGER_CODE/github.com/alxbl/lab")" github.com/lab
  check "worktree" eq "$(lib ledger_project "$LEDGER_CODE/github.com/alxbl/lab/main")" github.com/lab
  check "subdir" eq "$(lib ledger_project "$LEDGER_CODE/github.com/alxbl/lab/main/src")" github.com/lab
  check "forgejo" eq "$(lib ledger_project "$LEDGER_CODE/code.segfault.me/alxbl/fgj/main")" code.segfault.me/fgj
}

test_project_rejects_other_dirs() {
  check "other group" bash -c "! ( source $L/lib.sh; ledger_project $LEDGER_CODE/github.com/other/x )"
  check "user dir" bash -c "! ( source $L/lib.sh; ledger_project $LEDGER_CODE/github.com/alxbl )"
  check "outside" bash -c "! ( source $L/lib.sh; ledger_project /tmp )"
}

test_registry_section_stops_at_next_heading() {
  check "lab only" eq "$(lib ledger_registry_section github.com/lab | grep -c 'lab-\|aur-')" 3
  check "no aur leak" bash -c "! ( source $L/lib.sh; ledger_registry_section github.com/lab ) | grep -q aur-1"
  check "missing" eq "$(lib ledger_registry_section github.com/none)" ""
}

test_link_memory_creates_replaces_and_protects() {
  d=$LEDGER_CODE/github.com/alxbl/lab/main k=$CLAUDE_PROJECTS/$(lib ledger_memory_key "$d")/memory
  lib ledger_link_memory "$d" github.com/lab
  check "created" eq "$(readlink "$k")" "$LEDGER_ROOT/github.com/lab/memory"
  check "idempotent" eq "$(lib ledger_link_memory "$d" github.com/lab)" ""
  rm "$k"; mkdir "$k"; lib ledger_link_memory "$d" github.com/lab
  check "empty dir replaced" test -L "$k"
  rm "$k"; mkdir "$k"; echo x >"$k/keep.md"
  check "reports non-empty" bash -c "( source $L/lib.sh; ledger_link_memory $d github.com/lab ) | grep -q 'not empty'"
  check "kept files" test -f "$k/keep.md"
}

test_memory_key_matches_claude_encoding() {
  check "dots and slashes" eq "$(lib ledger_memory_key /home/alex/Code/code.segfault.me/alxbl/fgj/main)" -home-alex-Code-code-segfault-me-alxbl-fgj-main
}

test_start_hook_prints_project_section_and_links() {
  out=$(start "$LEDGER_CODE/github.com/alxbl/lab/main")
  check "section" bash -c "grep -q 'lab-2 second' <<<'$out'"
  check "no other project" bash -c "! grep -q aur-1 <<<'$out'"
  check "linked" test -L "$CLAUDE_PROJECTS/$(lib ledger_memory_key "$LEDGER_CODE/github.com/alxbl/lab/main")/memory"
}

test_start_hook_silent_outside_projects() {
  check "no output" eq "$(start "$LEDGER_CODE/github.com/other/x")" ""
  check "no output tmp" eq "$(jq -nc '{cwd:"/tmp"}' | "$L/session-start.sh")" ""
}

test_start_hook_reports_failed_pull_and_still_prints() {
  rm -rf "$T/origin.git"
  out=$(start "$LEDGER_CODE/github.com/alxbl/lab/main")
  check "warns" bash -c "grep -q 'pull failed' <<<'$out'"
  check "still prints section" bash -c "grep -q 'lab-1 first' <<<'$out'"
}

test_start_hook_missing_ledger_is_not_fatal() {
  rm -rf "$LEDGER_ROOT"
  out=$(start "$LEDGER_CODE/github.com/alxbl/lab/main")
  check "says where" bash -c "grep -q 'Ledger not found' <<<'$out'"
}

test_end_hook_commits_only_memory() {
  mkdir -p "$LEDGER_ROOT/github.com/lab/memory"
  echo m >"$LEDGER_ROOT/github.com/lab/memory/a.md"
  echo p >"$LEDGER_ROOT/github.com/lab/plan.md"
  "$L/session-end.sh"
  check "memory committed" eq "$(git -C "$LEDGER_ROOT" show --stat --format= HEAD | grep -c memory/a.md)" 1
  check "plan untouched" bash -c "git -C $LEDGER_ROOT status --short | grep -q 'plan.md'"
  check "pushed" eq "$(git -C "$LEDGER_ROOT" rev-parse HEAD)" "$(git -C "$T/origin.git" rev-parse HEAD)"
  before=$(git -C "$LEDGER_ROOT" rev-parse HEAD); "$L/session-end.sh"
  check "nothing to do" eq "$(git -C "$LEDGER_ROOT" rev-parse HEAD)" "$before"
}

test_end_hook_ignores_empty_memory_dirs() {
  mkdir -p "$LEDGER_ROOT/github.com/lab/memory" "$LEDGER_ROOT/github.com/aur/memory"
  echo m >"$LEDGER_ROOT/github.com/lab/memory/a.md"
  "$L/session-end.sh"
  check "committed" eq "$(git -C "$LEDGER_ROOT" log -1 --format=%s)" "chore(memory): sync session memory"
}

test_end_hook_survives_push_failure() {
  mkdir -p "$LEDGER_ROOT/github.com/lab/memory"; echo m >"$LEDGER_ROOT/github.com/lab/memory/a.md"
  rm -rf "$T/origin.git"
  check "exit 0" bash -c "$L/session-end.sh 2>/dev/null"
  check "still committed" eq "$(git -C "$LEDGER_ROOT" log -1 --format=%s)" "chore(memory): sync session memory"
}

# Checks the real registry when present: unique IDs, resolvable links.
test_real_registry_is_consistent() {
  real=${REAL_LEDGER:-$HOME_REAL/Code/code.segfault.me/alxbl/ledger/main}
  [[ -f $real/REGISTRY.md ]] || return 0
  dups=$(grep -oE '^- \[.\] [a-z.]+-[0-9]+' "$real/REGISTRY.md" | grep -oE '[a-z.]+-[0-9]+$' | sort | uniq -d)
  check "unique ids" eq "$dups" ""
  missing=$(grep -oE '→ [a-z][A-Za-z0-9._/-]*' "$real/REGISTRY.md" | sed 's/→ //' | while read -r p; do [[ -e $real/$p ]] || echo "$p"; done)
  check "links resolve" eq "$missing" ""
}

HOME_REAL=$HOME
names=("$@")
(( ${#names[@]} )) || mapfile -t names < <(declare -F | awk '{print $3}' | grep '^test_')
for t in "${names[@]}"; do
  setup; FAILED=0
  "$t"
  if (( FAILED )); then echo "FAIL $t"; FAIL=$((FAIL + 1)); else echo "ok   $t"; PASS=$((PASS + 1)); fi
  teardown
done
echo "$PASS passed, $FAIL failed"
(( FAIL == 0 ))
