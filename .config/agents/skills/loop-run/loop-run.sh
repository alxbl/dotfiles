#!/usr/bin/env bash
# Run one agent loop: take a slot, claim an item, run its roles one at a time until
# it needs a human, then run the retro. Run from inside an enrolled repo.
# Usage: loop-run.sh [ISSUE]   (no ISSUE: take the next eligible item)
# Exit: 0 human-review, 2 blocked, 3 not started, 1 error.
set -euo pipefail
here=$(dirname "$(readlink -f "$0")")
# shellcheck source=../loop-setup/lib.sh
source "$here/../loop-setup/lib.sh"

CLAUDE_BIN=${CLAUDE_BIN:-claude}
ITEM="" SLOT="" RESULT=error

# Take the first free slot within the WIP limits. Sets SLOT and keeps its lock open.
acquire_slot() {
  local n
  mkdir -p "$LOOP_STATE"
  (( $(held_items "$REPO" | wc -l) < $(repo_wip) )) || return 1
  for ((n = 1; n <= $(user_wip); n++)); do
    exec {LOCK_FD}>"$LOOP_STATE/slot-$n.lock"
    if flock -n "$LOCK_FD"; then SLOT=$n; return 0; fi
    exec {LOCK_FD}>&-
  done
  return 1
}

# Pick (or verify) the item and claim it. Serialized across loops so two loops
# never claim the same item.
claim() {
  local want=$1 eligible held
  exec {CLAIM_FD}>"$LOOP_STATE/claim.lock"
  flock "$CLAIM_FD"
  held=$(held_items "$REPO")
  eligible=$(list_issues | eligible_filter | grep -vxF -f <(echo "${held:-none}") || true)
  if [[ -n $want ]]; then
    grep -qxF "$want" <<<"$eligible" || return 1
    ITEM=$want
  else
    ITEM=$(head -n1 <<<"$eligible")
    [[ -n $ITEM ]] || return 1
  fi
  echo "$REPO#$ITEM" >"$LOOP_STATE/slot-$SLOT.item"
  gh label create "loop:$SLOT" --color BFD4F2 --description "Held by agent loop slot $SLOT" --force >/dev/null
  gh issue edit "$ITEM" --add-label agent:wip --add-label "loop:$SLOT" >/dev/null
  exec {CLAIM_FD}>&-
  ledger "$ITEM" "$SLOT" claim
}

release() {
  [[ -n $ITEM ]] || return 0
  gh issue edit "$ITEM" --remove-label agent:wip --remove-label "loop:$SLOT" >/dev/null || true
  echo "$ITEM $SLOT $RESULT" >"$RSTATE/results/$ITEM-$(date +%s)"
  rm -f "$LOOP_STATE/slot-$SLOT.item"
  ledger "$ITEM" "$SLOT" end "$RESULT"
}

# Block the item from STATE and record why in its blocked.md: block STATE NEED RESUME
block() {
  local d
  d=$(item_dir "$ITEM")
  mkdir -p "$d"
  printf '## %s loop:%s blocked this item\nat-round=%s\n**Needed:** %s\n**Resume:** %s\n\n' \
    "$(date -Is)" "$SLOT" "$(find "$d" -maxdepth 1 -name 'review-*.md' | wc -l)" "$2" "$3" >>"$d/blocked.md"
  gh issue edit "$ITEM" --add-label agent:blocked --remove-label "$1" >/dev/null
  ledger "$ITEM" "$SLOT" blocked "$1"
}

title() { [[ -n ${TMUX:-} ]] && tmux rename-window -t "${TMUX_PANE:-}" "$1" 2>/dev/null || true; }

# Run ROLE as a fresh headless agent. Records metrics and the role's friction notes.
run_role() {
  local role=$1 d log start rc=0 extra=() deny
  d=$(item_dir "$ITEM")
  mkdir -p "$d/logs"
  log="$d/logs/$(date +%Y%m%dT%H%M%S)-$role.json"
  mapfile -t deny < <(role_disallowed "$role")
  (( ${#deny[@]} )) && extra+=(--disallowedTools "${deny[@]}")
  title "l$SLOT #$ITEM $role"
  start=$(date +%s)
  "$CLAUDE_BIN" -p "/loop-$role $ITEM" --permission-mode dontAsk --model "$(role_model "$role")" \
    --settings "$LOOP_REPO_SETTINGS" --output-format json "${extra[@]}" </dev/null >"$log" 2>"$log.err" {LOCK_FD}>&- || rc=$?
  ledger "$ITEM" "$SLOT" "role:$role" "$(jq -r --arg rc "$rc" --arg s "$(( $(date +%s) - start ))" \
    '"rc=\($rc) error=\(.is_error | tostring) turns=\(.num_turns // "?") cost=\(.total_cost_usd // "?") secs=\($s)"' \
    "$log" 2>/dev/null || echo "rc=$rc unparsable")"
  collect "$role" "$log" loop-friction "$d/friction.md" "### $role $(date -Is)"
  collect "$role" "$log" loop-improvements "$RSTATE/improvements.tsv" ""
  return "$rc"
}

# Append the <TAG>...</TAG> block of a role's final message to FILE.
collect() {
  local role=$1 log=$2 tag=$3 file=$4 header=$5 text block
  text=$(jq -r '.result // ""' "$log" 2>/dev/null) || return 0
  [[ $text == *"<$tag>"*"</$tag>"* ]] || return 0
  block=${text#*"<$tag>"}
  block=${block%%"</$tag>"*}
  [[ -n ${block//[[:space:]]/} ]] || return 0
  if [[ $tag == loop-improvements ]]; then
    while IFS= read -r line; do
      [[ -n ${line//[[:space:]]/} ]] && printf '%s\t%s\t%s\n' "$(date -Is)" "$ITEM" "$line"
    done <<<"$block" >>"$file"
  else
    printf '%s\n%s\n\n' "$header" "$(sed '/^[[:space:]]*$/d' <<<"$block")" >>"$file"
  fi
}

pipeline() {
  local state role fails=0 max
  max=$(cfg max_review_rounds 3)
  while :; do
    state=$(item_state "$ITEM")
    case $state in
      agent:human-review) RESULT=human-review; return ;;
      agent:blocked) RESULT=blocked; return ;;
      agent:explore) role=explore ;;
      agent:explored) role=plan ;;
      agent:planned) role=contribute ;;
      agent:review) role=review ;;
      agent:changes)
        if (( $(change_rounds "$ITEM") >= max )); then
          block "$state" "Review asked for changes $max times (max_review_rounds). A human must settle the open findings." \
            "Comment with guidance and set \`agent:changes\`, or take over the PR."
          RESULT=blocked; return
        fi
        role=contribute ;;
      *) RESULT=error; return ;;
    esac
    if run_role "$role" && [[ $(item_state "$ITEM") != "$state" ]]; then
      fails=0; continue
    fi
    if (( ++fails >= 2 )); then
      block "$state" "The $role role failed twice without moving the item on. Logs are in \`$(item_dir "$ITEM")/logs\`." \
        "Fix the cause, then remove \`agent:blocked\` and set \`$state\` again."
      RESULT=blocked; return
    fi
  done
}

main() {
  cd "$(git rev-parse --show-toplevel)"
  [[ -f $LOOP_REPO_CONFIG ]] || die 3 "$LOOP_REPO_CONFIG missing: repo is not enrolled"
  [[ -f $LOOP_REPO_SETTINGS ]] || die 3 "$LOOP_REPO_SETTINGS missing: repo is not enrolled"
  for role in "${LOOP_ROLES[@]}"; do
    [[ -f $LOOP_SKILLS_DIR/loop-$role/SKILL.md ]] || die 3 "skill loop-$role is not installed in $LOOP_SKILLS_DIR"
  done
  REPO=$(repo_slug)
  init_work "$REPO"
  RSTATE=$(repo_state)
  mkdir -p "$RSTATE/results"
  acquire_slot || die 3 "no free slot"
  claim "${1:-}" || die 3 "no eligible item${1:+ (#$1)}"
  trap release EXIT
  pipeline
  run_role retro || true
  title "l$SLOT idle"
  case $RESULT in human-review) exit 0 ;; blocked) exit 2 ;; *) exit 1 ;; esac
}

main "$@"
