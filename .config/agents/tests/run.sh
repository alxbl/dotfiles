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
  export LOOP_SKILLS_DIR=$T/skills
  for r in explore plan contribute review retro; do mkdir -p "$T/skills/loop-$r"; touch "$T/skills/loop-$r/SKILL.md"; done
  mkdir -p "$FAKE_GH/issues" "$T/repo/.agents"
  : >"$FAKE_GH/verdicts"
  printf -- '---\nwip: 1\npoll_interval: 1\n---\n' >"$LOOP_USER_CONFIG"
  printf -- '---\nbase: main\n---\nnotes\n' >"$T/repo/.agents/loop.md"
  echo '{}' >"$T/repo/.agents/settings.json"
  git -C "$T/repo" init -q
  RSTATE=$T/repo/.agents/work
  cd "$T/repo" || exit 1
}

teardown() { cd / && rm -rf "$T"; }

issue() { # issue N CREATED LABEL...
  local d=$FAKE_GH/issues/$1; mkdir -p "$d"; echo "$2" >"$d/created"
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
  issue 9 2026-01-08 agent:planned
  check "order" eq "$(gh issue list | lib eligible_filter | paste -sd' ' -)" "2 7 9 3 8 1"
}

test_change_rounds_reset_after_block() {
  local d=$RSTATE/1; mkdir -p "$d"
  review() { echo "verdict=$2" >"$d/review-$1.md"; }
  check "no pr" eq "$(lib change_rounds 1)" 0
  echo 9 >"$d/pr"
  review 1 changes; review 2 changes
  check "two rounds" eq "$(lib change_rounds 1)" 2
  printf '## t loop:1 blocked this item\nat-round=2\n' >"$d/blocked.md"
  check "reset by block" eq "$(lib change_rounds 1)" 0
  review 3 changes
  check "counts after block" eq "$(lib change_rounds 1)" 1
  review 4 pass
  check "reset by pass" eq "$(lib change_rounds 1)" 0
  review 5 changes
  check "counts after pass" eq "$(lib change_rounds 1)" 1
}

test_role_model_defaults_and_overrides() {
  check "explore" eq "$(lib role_model explore)" opus
  check "plan" eq "$(lib role_model plan)" opus
  check "contribute" eq "$(lib role_model contribute)" sonnet
  check "review" eq "$(lib role_model review)" sonnet
  check "retro" eq "$(lib role_model retro)" opus
  printf -- '---\nmodel_review: haiku\nmodel_plan: sonnet\n---\n' >"$LOOP_USER_CONFIG"
  check "user" eq "$(lib role_model review)" haiku
  printf -- '---\nmodel_review: opus\n---\n' >.agents/loop.md
  check "repo wins" eq "$(lib role_model review)" opus
  check "user other" eq "$(lib role_model plan)" sonnet
}

test_init_work_excludes_and_registers() {
  lib init_work me/repo
  lib init_work me/repo
  check "work dir" test -d "$RSTATE"
  check "excluded once" eq "$(grep -cxF '.agents/work/' .git/info/exclude)" 1
  check "worktrees excluded" grep -qxF .worktrees/ .git/info/exclude
  check "registered once" eq "$(cat "$LOOP_STATE/repos")" "me/repo"$'\t'"$(realpath "$T/repo")"
}

# --- loop-run ----------------------------------------------------------------

test_loop_run_happy_path() {
  issue 1 2026-01-01 agent:explore
  echo pass >"$FAKE_GH/verdicts"
  "$LOOP_RUN" >/dev/null 2>&1; local rc=$?
  check "exit 0" eq "$rc" 0
  check "labels" eq "$(labels 1)" agent:human-review
  check "roles in order" eq "$(grep -o '/loop-[a-z]* 1' "$FAKE_GH/calls.log" | paste -sd' ' -)" \
    "/loop-explore 1 /loop-plan 1 /loop-contribute 1 /loop-review 1 /loop-retro 1"
  check "models" eq "$(grep -o '/loop-[a-z]* 1.*--model [a-z]*' "$FAKE_GH/calls.log" | sed 's|/loop-\([a-z]*\) .*--model |\1=|' | paste -sd' ' -)" \
    "explore=opus plan=opus contribute=sonnet review=sonnet retro=opus"
  check "dontAsk" grep -q -- '--permission-mode dontAsk --model [a-z]* --settings .agents/settings.json' "$FAKE_GH/calls.log"
  check "explore cannot edit code" grep -q -- '/loop-explore 1.*--disallowedTools Edit(/.*/.worktrees/\*\*) Write(/.*/.worktrees/\*\*) NotebookEdit' "$FAKE_GH/calls.log"
  check "explore may edit its context" grep -q -- '/loop-explore 1.*--allowedTools Edit(/.*/.agents/work/\*\*) Write(/.*/.agents/work/\*\*)' "$FAKE_GH/calls.log"
  check "contribute can edit" test -z "$(grep -- '/loop-contribute 1.*--disallowedTools' "$FAKE_GH/calls.log")"
  check "one-command rule passed to every role" eq "$(grep -c -- '--append-system-prompt Run exactly one command per Bash call' "$FAKE_GH/calls.log")" 5
  check "no github comments" test -z "$(grep -E 'comment|pr (create|review)' "$FAKE_GH/calls.log")"
  check "context files" test -s "$RSTATE/1/spec.md" -a -s "$RSTATE/1/plan.md" -a -s "$RSTATE/1/review-1.md"
  check "result file" eq "$(cat "$RSTATE"/results/1-*)" "1 1 human-review"
  check "slot item cleared" test ! -e "$LOOP_STATE/slot-1.item"
  check "metrics" grep -q $'role:review\trc=0 error=false turns=3 cost=0.01' "$RSTATE/ledger.tsv"
  check "friction" grep -q 'missing-doc: contribute note' "$RSTATE/1/friction.md"
  check "improvements" grep -q $'\t1\tPROTOCOL.md\tprotocol\tclarify X$' "$RSTATE/improvements.tsv"
}

test_loop_run_uses_configured_model() {
  printf -- '---\nmodel_review: opus\n---\n' >.agents/loop.md
  issue 1 2026-01-01 agent:review
  mkdir -p "$RSTATE/1"; echo 1 >"$RSTATE/1/pr"
  echo pass >"$FAKE_GH/verdicts"
  "$LOOP_RUN" >/dev/null 2>&1
  check "review on opus" grep -q -- '/loop-review 1.*--model opus' "$FAKE_GH/calls.log"
}

test_loop_run_blocks_after_max_rounds() {
  issue 1 2026-01-01 agent:explored
  printf 'changes\nchanges\nchanges\npass\n' >"$FAKE_GH/verdicts"
  "$LOOP_RUN" 1 >/dev/null 2>&1; local rc=$?
  check "exit 2" eq "$rc" 2
  check "labels" eq "$(labels 1)" agent:blocked
  check "contribute runs" eq "$(grep -c '/loop-contribute 1' "$FAKE_GH/calls.log")" 3
  check "block notice" grep -q 'max_review_rounds' "$RSTATE/1/blocked.md"
  check "block round" grep -qx 'at-round=3' "$RSTATE/1/blocked.md"
  check "retro still runs" grep -q '/loop-retro 1' "$FAKE_GH/calls.log"
}

test_loop_run_blocks_after_two_stuck_runs() {
  issue 1 2026-01-01 agent:explore
  printf '#!/bin/sh\necho nothing\n' >"$FAKE_GH/role-explore"; chmod +x "$FAKE_GH/role-explore"
  "$LOOP_RUN" >/dev/null 2>&1; local rc=$?
  check "exit 2" eq "$rc" 2
  check "two attempts" eq "$(grep -c '/loop-explore 1' "$FAKE_GH/calls.log")" 2
  check "labels" eq "$(labels 1)" agent:blocked
  check "block entry" grep -q '^\*\*Needed:\*\* The explore role failed twice' "$RSTATE/1/blocked.md"
  check "resume line" grep -q '^\*\*Resume:\*\* .*agent:explore' "$RSTATE/1/blocked.md"
  check "round recorded" grep -qx 'at-round=0' "$RSTATE/1/blocked.md"
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

# Run the explore role with FINAL as its raw final message; print the friction file.
friction_from() {
  issue 1 2026-01-01 agent:explore
  printf '#!/bin/sh\ngh issue edit "$1" --remove-label agent:explore --add-label agent:blocked\nprintf "%%s" "$FINAL"\n' >"$FAKE_GH/role-explore"
  chmod +x "$FAKE_GH/role-explore"
  FINAL=$1 "$LOOP_RUN" >/dev/null 2>&1
  cat "$RSTATE/1/friction.md" 2>/dev/null
}

test_collect_friction_edge_cases() {
  check "block with tags on own lines" grep -q -- '- spec-gap: a' <(friction_from $'done\n<loop-friction>\n- spec-gap: a\n</loop-friction>')
}

test_collect_ignores_missing_empty_and_unparsable() {
  check "no block" eq "$(friction_from 'done')" ""
  teardown; setup
  check "empty block" eq "$(friction_from $'done\n<loop-friction>\n\n</loop-friction>')" ""
  teardown; setup
  check "unclosed tag" eq "$(friction_from $'<loop-friction>\n- other: a')" ""
  teardown; setup
  issue 1 2026-01-01 agent:explore
  echo 'not json' >"$FAKE_GH/raw-explore"
  "$LOOP_RUN" >/dev/null 2>&1; local rc=$?
  check "survives unparsable output" eq "$rc" 2
  check "ledger notes it" grep -q 'rc=0 unparsable' "$RSTATE/ledger.tsv"
}

test_collect_inline_tags() {
  check "inline block" grep -q -- '- other: x (y)' <(friction_from 'done <loop-friction>- other: x (y)</loop-friction>')
}

test_loop_run_releases_on_termination() {
  issue 1 2026-01-01 agent:explore
  printf '#!/bin/sh\nsleep 30 &\necho $! >"$FAKE_GH/sleeper"\nwait\n' >"$FAKE_GH/role-explore"; chmod +x "$FAKE_GH/role-explore"
  "$LOOP_RUN" >/dev/null 2>&1 & local pid=$!
  for _ in $(seq 50); do [[ $(labels 1) == *agent:wip* ]] && break; sleep 0.1; done
  check "claimed" eq "$(labels 1)" "agent:explore agent:wip loop:1"
  kill -TERM "$pid"
  wait "$pid" 2>/dev/null
  check "claim released" eq "$(labels 1)" agent:explore
  check "slot freed" test ! -e "$LOOP_STATE/slot-1.item"
  check "result recorded" eq "$(cat "$RSTATE"/results/1-*)" "1 1 error"
  check "slot lock free although the role is still running" flock -n "$LOOP_STATE/slot-1.lock" true
  kill "$(cat "$FAKE_GH/sleeper")" 2>/dev/null || true
}

test_loop_run_concurrent_starts_claim_once() {
  printf -- '---\nwip: 2\n---\n' >"$LOOP_USER_CONFIG"
  issue 1 2026-01-01 agent:explore
  printf '#!/bin/sh\nsleep 1\ngh issue edit "$1" --remove-label agent:explore --add-label agent:blocked\n' >"$FAKE_GH/role-explore"
  chmod +x "$FAKE_GH/role-explore"
  "$LOOP_RUN" 1 >/dev/null 2>&1 & local a=$!
  "$LOOP_RUN" 1 >/dev/null 2>&1 & local b=$!
  wait "$a"; local ra=$?; wait "$b"; local rb=$?
  check "one runs, one is refused" eq "$(printf '%s\n' "$ra" "$rb" | sort | paste -sd' ' -)" "2 3"
  check "claimed once" eq "$(grep -c $'\tclaim\t*$' "$RSTATE/ledger.tsv")" 1
  check "role ran once" eq "$(grep -c '/loop-explore 1' "$FAKE_GH/calls.log")" 1
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
  check "slot 2" grep -q $'\t1\t2\tclaim' "$RSTATE/ledger.tsv"
}

test_loop_run_ignores_item_file_left_by_a_killed_loop() {
  issue 1 2026-01-01 agent:explore
  mkdir -p "$LOOP_STATE"; echo "me/repo#1" >"$LOOP_STATE/slot-1.item"
  echo pass >"$FAKE_GH/verdicts"
  "$LOOP_RUN" >/dev/null 2>&1; local rc=$?
  check "exit 0" eq "$rc" 0
  check "labels" eq "$(labels 1)" agent:human-review
}

test_loop_run_rejects_ineligible_item() {
  issue 1 2026-01-01 agent:blocked
  "$LOOP_RUN" 1 >/dev/null 2>&1; local rc=$?
  check "exit 3" eq "$rc" 3
  check "no claude" test ! -s <(grep '^claude' "$FAKE_GH/calls.log")
}

test_loop_run_requires_installed_skills() {
  issue 1 2026-01-01 agent:explore
  rm "$T/skills/loop-plan/SKILL.md"
  "$LOOP_RUN" >/dev/null 2>&1; local rc=$?
  check "exit 3" eq "$rc" 3
  check "not claimed" eq "$(labels 1)" agent:explore
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

test_poll_redispatches_expired_pending() {
  issue 1 2026-01-01 agent:explore
  check "dispatch" eq "$("$POLL" --once)" "dispatch 1"
  touch -d '10 minutes ago' "$RSTATE/pending/1"
  check "expired pending dispatched again" eq "$("$POLL" --once)" "dispatch 1"
}

test_poll_counts_slots_held_by_other_repos() {
  issue 1 2026-01-01 agent:explore
  mkdir -p "$LOOP_STATE"; echo "me/other#5" >"$LOOP_STATE/slot-1.item"
  flock "$LOOP_STATE/slot-1.lock" sleep 30 & local holder=$!
  sleep 0.2
  check "no dispatch while the user limit is used" eq "$("$POLL" --once)" ""
  check "loop-run refuses" eq "$("$LOOP_RUN" >/dev/null 2>&1; echo $?)" 3
  pkill -P "$holder"; kill "$holder"; wait "$holder" 2>/dev/null
  rm -f "$LOOP_STATE/slot-1.item"
  check "dispatch once free" eq "$("$POLL" --once)" "dispatch 1"
}

test_requeue_once_then_block() {
  local rq=$SKILLS/loop-orchestrate/requeue.sh
  issue 3 2026-01-01 agent:review agent:wip loop:1
  check "first stale requeues" eq "$("$rq" 3 1)" requeued
  check "claim released" eq "$(labels 3)" agent:review
  check "ledger line" grep -q $'\t3\t-\trequeue\t' "$RSTATE/ledger.tsv"
  gh issue edit 3 --add-label agent:wip --add-label loop:1
  check "second stale blocks" eq "$("$rq" 3 1)" blocked
  check "labels" eq "$(labels 3)" agent:blocked
  check "block entry" grep -q 'went stale twice' "$RSTATE/3/blocked.md"
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

test_poll_drain_waits_for_running_loop() {
  issue 1 2026-01-01 agent:explore agent:wip loop:1
  issue 2 2026-01-02 agent:explore
  mkdir -p "$LOOP_STATE"; touch "$LOOP_STATE/drain"; echo "me/repo#1" >"$LOOP_STATE/slot-1.item"
  flock "$LOOP_STATE/slot-1.lock" sleep 30 & local holder=$!
  sleep 0.2
  local out rc; out=$("$POLL" --once); rc=$?
  check "no event while the loop runs" eq "$out" ""
  check "still running is not an error" eq "$rc" 0
  check "nothing dispatched" test ! -e "$RSTATE/pending/2"
  pkill -P "$holder"; kill "$holder"; wait "$holder" 2>/dev/null
  check "drain once it ends" eq "$("$POLL" --once)" "drain"
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
  mkdir -p "$LOOP_STATE" "$T/a/.agents/work" "$T/b/.agents/work" "$T/c"
  printf 't\t1\tCLAUDE.md\tmissing-rule\tdoc A\nt\t2\tCLAUDE.md\tmissing-rule\tdoc B\n' >"$T/a/.agents/work/improvements.tsv"
  printf 't\t5\tCLAUDE.md\tmissing-rule\tdoc C\nt\t6\tPROTOCOL.md\tprotocol\tfix P\n' >"$T/b/.agents/work/improvements.tsv"
  printf 'o/a\t%s\no/b\t%s\no/c\t%s\n' "$T/a" "$T/b" "$T/c" >"$LOOP_STATE/repos"
  check "top group" eq "$("$r" | head -n1 | cut -f1-4)" $'3\tCLAUDE.md\tmissing-rule\to/a,o/b'
  check "filter" eq "$("$r" PROTOCOL | cut -f1,2)" $'1\tPROTOCOL.md'
}

test_labels_creates_every_state() {
  "$SKILLS/loop-setup/labels.sh" >/dev/null
  check "all labels" eq "$(grep -c '^gh label create agent:' "$FAKE_GH/calls.log")" 8
  check "planned" grep -q '^gh label create agent:planned ' "$FAKE_GH/calls.log"
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
