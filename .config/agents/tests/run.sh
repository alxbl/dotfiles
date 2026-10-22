#!/usr/bin/env bash
# Unit tests for the agent loop scripts. Uses fake gh and claude; touches no network.
# Usage: tests/run.sh [test-name...]
set -uo pipefail
TESTS=$(dirname "$(readlink -f "$0")")
SKILLS=$TESTS/../skills
LOOP_RUN=$SKILLS/loop-run/loop-run.sh
POLL=$SKILLS/loop-orchestrate/poll.sh
PASS=0 FAIL=0

setup() {
  T=$(mktemp -d)
  export FAKE_GH=$T/gh FAKE_REPO=me/repo LOOP_STATE=$T/state LOOP_USER_CONFIG=$T/loop.md
  export PATH=$TESTS/stubs:$PATH CLAUDE_BIN=$TESTS/stubs/claude PENDING_TTL=300
  unset TMUX
  mkdir -p "$FAKE_GH/issues" "$FAKE_GH/prs" "$T/repo/.agents"
  : >"$FAKE_GH/verdicts"
  printf -- '---\nwip: 1\npoll_interval: 1\n---\n' >"$LOOP_USER_CONFIG"
  printf -- '---\nbase: main\n---\nnotes\n' >"$T/repo/.agents/loop.md"
  echo '{}' >"$T/repo/.agents/settings.json"
  git -C "$T/repo" init -q
  RSTATE=$LOOP_STATE/me-repo
  cd "$T/repo" || exit 1
}

teardown() { cd / && rm -rf "$T"; }

issue() { # issue N CREATED LABEL...
  local d=$FAKE_GH/issues/$1; mkdir -p "$d"; echo "$2" >"$d/created"; : >"$d/comments"
  shift 2; printf '%s\n' "$@" >"$d/labels"
}

labels() { sort "$FAKE_GH/issues/$1/labels" | sed '/^$/d' | paste -sd' ' -; }

check() { # check DESCRIPTION COMMAND...
  if "${@:2}"; then return 0; fi
  echo "    FAIL: $1"; FAILED=1
}
eq() { [[ $1 == "$2" ]] || { echo "    expected [$2] got [$1]"; return 1; }; }

lib() { ( source "$SKILLS/loop-setup/lib.sh"; "$@" ); }

# --- lib ---------------------------------------------------------------------

test_fm_get_reads_front_matter_only() {
  printf -- '---\nwip: 3  # comment\nname: "x y"\n---\nwip: 9\n' >"$T/f.md"
  check "wip" eq "$(lib fm_get "$T/f.md" wip)" 3
  check "quoted" eq "$(lib fm_get "$T/f.md" name)" "x y"
  check "missing key" eq "$(lib fm_get "$T/f.md" nope)" ""
  printf 'wip: 4\n' >"$T/g.md"
  check "no front matter" eq "$(lib fm_get "$T/g.md" wip)" ""
}

test_cfg_precedence_and_repo_wip_only_lowers() {
  printf -- '---\nwip: 2\nmax_review_rounds: 5\n---\n' >"$LOOP_USER_CONFIG"
  check "user value" eq "$(lib cfg max_review_rounds 3)" 5
  check "default" eq "$(lib cfg poll_interval 60)" 60
  printf -- '---\nmax_review_rounds: 1\nwip: 9\n---\n' >.agents/loop.md
  check "repo wins" eq "$(lib cfg max_review_rounds 3)" 1
  check "repo cannot raise wip" eq "$(lib repo_wip)" 2
  printf -- '---\nwip: 1\n---\n' >.agents/loop.md
  check "repo lowers wip" eq "$(lib repo_wip)" 1
}

test_eligible_order_and_exclusions() {
  issue 1 2026-01-01 agent:explore
  issue 2 2026-01-02 agent:changes
  issue 3 2026-01-03 agent:explored
  issue 4 2026-01-04 agent:explore agent:wip
  issue 5 2026-01-05 agent:review agent:blocked
  issue 6 2026-01-06 bug
  issue 7 2026-01-07 agent:review
  issue 8 2025-12-31 agent:explore
  check "order" eq "$(gh issue list | lib eligible_filter | paste -sd' ' -)" "2 7 3 8 1"
}

test_change_rounds_reset_after_block() {
  issue 1 2026-01-01 agent:changes
  mkdir -p "$FAKE_GH/prs/9"; echo '<!-- loop:pr issue=1 -->' >"$FAKE_GH/prs/9/body"; : >"$FAKE_GH/prs/9/comments"
  gh pr comment 9 --body '<!-- loop:review round=1 verdict=changes -->'
  gh pr comment 9 --body '<!-- loop:review round=2 verdict=changes -->'
  check "two rounds" eq "$(lib change_rounds 1)" 2
  gh issue comment 1 --body '<!-- loop:blocked --> stuck'
  check "reset by block" eq "$(lib change_rounds 1)" 0
  gh pr comment 9 --body '<!-- loop:review round=3 verdict=changes -->'
  check "counts after block" eq "$(lib change_rounds 1)" 1
  gh pr comment 9 --body '<!-- loop:review round=4 verdict=pass -->'
  check "reset by pass" eq "$(lib change_rounds 1)" 0
}

# --- loop-run ----------------------------------------------------------------

test_loop_run_happy_path() {
  issue 1 2026-01-01 agent:explore
  echo pass >"$FAKE_GH/verdicts"
  "$LOOP_RUN" >/dev/null 2>&1; local rc=$?
  check "exit 0" eq "$rc" 0
  check "labels" eq "$(labels 1)" agent:human-review
  check "roles in order" eq "$(grep -o '/loop-[a-z]* 1' "$FAKE_GH/calls.log" | paste -sd' ' -)" \
    "/loop-explore 1 /loop-contribute 1 /loop-review 1 /loop-retro 1"
  check "dontAsk" grep -q -- '--permission-mode dontAsk --settings .agents/settings.json' "$FAKE_GH/calls.log"
  check "retro sees state" grep -q -- "/loop-retro 1.*--add-dir $LOOP_STATE" "$FAKE_GH/calls.log"
  check "explore read-only" grep -q -- "/loop-explore 1.*--disallowedTools Edit Write" "$FAKE_GH/calls.log"
  check "contribute can edit" test -z "$(grep -- '/loop-contribute 1.*--disallowedTools' "$FAKE_GH/calls.log")"
  check "claim comment" grep -q 'loop:1 claimed' "$FAKE_GH/issues/1/comments"
  check "result file" eq "$(cat "$RSTATE"/results/1-*)" "1 1 human-review"
  check "slot item cleared" test ! -e "$LOOP_STATE/slot-1.item"
  check "metrics" grep -q $'role:review\trc=0 error=false turns=3 cost=0.01' "$RSTATE/ledger.tsv"
  check "friction" grep -q 'missing-doc: contribute note' "$RSTATE/friction/1.md"
  check "improvements" grep -q $'\t1\tPROTOCOL.md\tprotocol\tclarify X$' "$RSTATE/improvements.tsv"
}

test_loop_run_blocks_after_max_rounds() {
  issue 1 2026-01-01 agent:explored
  printf 'changes\nchanges\nchanges\npass\n' >"$FAKE_GH/verdicts"
  "$LOOP_RUN" 1 >/dev/null 2>&1; local rc=$?
  check "exit 2" eq "$rc" 2
  check "labels" eq "$(labels 1)" agent:blocked
  check "contribute runs" eq "$(grep -c '/loop-contribute 1' "$FAKE_GH/calls.log")" 3
  check "block comment" grep -q 'loop:blocked.*max_review_rounds' <(tr -d '\n' <"$FAKE_GH/issues/1/comments")
  check "retro still runs" grep -q '/loop-retro 1' "$FAKE_GH/calls.log"
}

test_loop_run_blocks_after_two_stuck_runs() {
  issue 1 2026-01-01 agent:explore
  printf '#!/bin/sh\necho nothing\n' >"$FAKE_GH/role-explore"; chmod +x "$FAKE_GH/role-explore"
  "$LOOP_RUN" >/dev/null 2>&1; local rc=$?
  check "exit 2" eq "$rc" 2
  check "two attempts" eq "$(grep -c '/loop-explore 1' "$FAKE_GH/calls.log")" 2
  check "labels" eq "$(labels 1)" agent:blocked
}

test_loop_run_role_blocks_itself() {
  issue 1 2026-01-01 agent:explore
  printf '#!/bin/sh\ngh issue edit "$1" --remove-label agent:explore --add-label agent:blocked\n' >"$FAKE_GH/role-explore"
  chmod +x "$FAKE_GH/role-explore"
  "$LOOP_RUN" >/dev/null 2>&1; local rc=$?
  check "exit 2" eq "$rc" 2
  check "one attempt" eq "$(grep -c '/loop-explore 1' "$FAKE_GH/calls.log")" 1
  check "result" eq "$(cat "$RSTATE"/results/1-*)" "1 1 blocked"
}

test_loop_run_no_free_slot() {
  issue 1 2026-01-01 agent:explore
  mkdir -p "$LOOP_STATE"; flock "$LOOP_STATE/slot-1.lock" sleep 30 & local holder=$!
  sleep 0.2
  "$LOOP_RUN" >/dev/null 2>&1; local rc=$?
  kill "$holder"
  check "exit 3" eq "$rc" 3
  check "not claimed" eq "$(labels 1)" agent:explore
}

test_loop_run_uses_second_slot() {
  printf -- '---\nwip: 2\n---\n' >"$LOOP_USER_CONFIG"
  issue 1 2026-01-01 agent:explore
  echo pass >"$FAKE_GH/verdicts"
  mkdir -p "$LOOP_STATE"; flock "$LOOP_STATE/slot-1.lock" sleep 30 & local holder=$!
  sleep 0.2
  "$LOOP_RUN" >/dev/null 2>&1; local rc=$?
  kill "$holder"
  check "exit 0" eq "$rc" 0
  check "slot 2" grep -q 'loop:2 claimed' "$FAKE_GH/issues/1/comments"
}

test_loop_run_rejects_ineligible_item() {
  issue 1 2026-01-01 agent:blocked
  "$LOOP_RUN" 1 >/dev/null 2>&1; local rc=$?
  check "exit 3" eq "$rc" 3
  check "no claude" test ! -s <(grep '^claude' "$FAKE_GH/calls.log")
}

test_loop_run_requires_enrollment() {
  rm .agents/loop.md
  issue 1 2026-01-01 agent:explore
  "$LOOP_RUN" >/dev/null 2>&1; local rc=$?
  check "exit 3" eq "$rc" 3
}

# --- poll --------------------------------------------------------------------

test_poll_dispatches_within_wip_once() {
  issue 1 2026-01-01 agent:explore
  issue 2 2026-01-02 agent:explored
  check "first dispatch" eq "$("$POLL" --once)" "dispatch 2"
  check "pending not redispatched" eq "$("$POLL" --once)" ""
  printf -- '---\nwip: 2\n---\n' >"$LOOP_USER_CONFIG"
  check "second slot" eq "$("$POLL" --once)" "dispatch 1"
}

test_poll_respects_repo_wip() {
  printf -- '---\nwip: 3\n---\n' >"$LOOP_USER_CONFIG"
  printf -- '---\nwip: 1\n---\n' >.agents/loop.md
  issue 1 2026-01-01 agent:explore
  issue 2 2026-01-02 agent:explore
  check "one dispatch" eq "$("$POLL" --once)" "dispatch 1"
}

test_poll_reports_done() {
  mkdir -p "$RSTATE/results"; echo "4 1 human-review" >"$RSTATE/results/4-1"
  check "done" eq "$("$POLL" --once)" "done 4 human-review"
  check "consumed" test ! -e "$RSTATE/results/4-1"
}

test_poll_reports_stale_once() {
  issue 3 2026-01-01 agent:review agent:wip loop:1
  check "stale" eq "$("$POLL" --once)" "stale 3 1"
  check "only once" eq "$("$POLL" --once)" ""
}

test_poll_idle_once_per_blocked_set() {
  issue 1 2026-01-01 agent:blocked
  check "idle" eq "$("$POLL" --once)" "idle 1"
  check "quiet" eq "$("$POLL" --once)" ""
  issue 2 2026-01-02 agent:blocked
  check "new set" eq "$("$POLL" --once)" "idle 2"
}

test_poll_drain() {
  issue 1 2026-01-01 agent:explore
  mkdir -p "$LOOP_STATE"; touch "$LOOP_STATE/drain"
  check "drain" eq "$("$POLL" --once)" "drain"
}

test_poll_status() {
  issue 1 2026-01-01 agent:explore
  issue 2 2026-01-01 agent:blocked
  check "status" eq "$("$POLL" --status)" \
    "repo=me/repo slots_free=1/1 running= eligible=1 blocked=1 human-review=0 drain=no"
}

# --- recurrence --------------------------------------------------------------

test_recurrence_groups_across_repos() {
  local r=$SKILLS/loop-retro/recurrence.sh
  check "empty" eq "$("$r")" "no earlier proposals"
  mkdir -p "$LOOP_STATE/a-x" "$LOOP_STATE/b-y"
  printf 't\t1\tCLAUDE.md\tmissing-rule\tdoc A\nt\t2\tCLAUDE.md\tmissing-rule\tdoc B\n' >"$LOOP_STATE/a-x/improvements.tsv"
  printf 't\t5\tCLAUDE.md\tmissing-rule\tdoc C\nt\t6\tPROTOCOL.md\tprotocol\tfix P\n' >"$LOOP_STATE/b-y/improvements.tsv"
  check "top group" eq "$("$r" | head -n1 | cut -f1-4)" $'3\tCLAUDE.md\tmissing-rule\ta-x,b-y'
  check "filter" eq "$("$r" PROTOCOL | cut -f1,2)" $'1\tPROTOCOL.md'
}

# -----------------------------------------------------------------------------

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
