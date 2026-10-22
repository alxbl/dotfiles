#!/usr/bin/env bash
# Wait until the orchestrator has something to do, print one event per line, and exit.
# Run from inside an enrolled repo.
# Usage: poll.sh [--once | --status]
# Events:
#   dispatch <N>          start a loop for issue N (a slot is free)
#   done <N> <result>     a loop ended: human-review | blocked | error
#   stale <N> <slot>      issue N is claimed by a slot no loop holds
#   idle <blocked>        nothing to do, no loop running, <blocked> items wait on a human
#   drain                 drain requested and no loop of this repo is running
set -euo pipefail
here=$(dirname "$(readlink -f "$0")")
# shellcheck source=../loop-setup/lib.sh
source "$here/../loop-setup/lib.sh"

PENDING_TTL=${PENDING_TTL:-300}

# Print issues dispatched recently whose loop has not taken a slot yet.
pending() {
  local f now
  now=$(date +%s)
  for f in "$RSTATE"/pending/*; do
    [[ -e $f ]] || continue
    if (( now - $(stat -c %Y "$f") > PENDING_TTL )); then rm -f "$f"; else echo "${f##*/}"; fi
  done
}

status() {
  local issues
  issues=$(list_issues)
  printf 'repo=%s slots_free=%s/%s running=%s eligible=%s blocked=%s human-review=%s drain=%s\n' \
    "$REPO" "$(free_slots)" "$(user_wip)" "$(held_items "$REPO" | paste -sd, -)" \
    "$(eligible_filter <<<"$issues" | wc -l)" \
    "$(jq '[.[] | select(any(.labels[].name; . == "agent:blocked"))] | length' <<<"$issues")" \
    "$(jq '[.[] | select(any(.labels[].name; . == "agent:human-review"))] | length' <<<"$issues")" \
    "$([[ -e $LOOP_STATE/drain ]] && echo yes || echo no)"
}

poll_once() {
  local f n slot result issues held busy free cap blocked mark
  EVENTS=()
  for f in "$RSTATE"/results/*; do
    [[ -e $f ]] || continue
    read -r n slot result <"$f"
    EVENTS+=("done $n $result")
    ledger "$n" "$slot" done "$result"
    rm -f "$f" "$RSTATE/pending/$n"
  done

  held=$(held_items "$REPO")
  for n in $held; do rm -f "$RSTATE/pending/$n"; done
  busy=$( { echo "$held"; pending; } | sed '/^$/d' | sort -u)

  if [[ -e $LOOP_STATE/drain ]]; then
    [[ -z $held ]] && EVENTS+=(drain)
    return
  fi

  issues=$(list_issues)

  free=$(( $(free_slots) - $(pending | wc -l) ))
  cap=$(( $(repo_wip) - $(sed '/^$/d' <<<"$busy" | wc -l) ))
  (( cap < free )) && free=$cap
  if (( free > 0 )); then
    for n in $(eligible_filter <<<"$issues" | grep -vxF -f <(echo "${busy:-none}") | head -n "$free"); do
      touch "$RSTATE/pending/$n"
      EVENTS+=("dispatch $n")
      ledger "$n" - dispatch
    done
  fi

  while read -r n slot; do
    [[ -n $n ]] || continue
    slot_held "$slot" || grep -qxF "$n" <<<"$busy" || {
      mark="$RSTATE/stale-$n"
      [[ -e $mark ]] || { touch "$mark"; EVENTS+=("stale $n $slot"); }
    }
  done < <(jq -r '.[] | select(any(.labels[].name; . == "agent:wip"))
    | "\(.number) \([.labels[].name | select(startswith("loop:")) | ltrimstr("loop:")] | .[0] // "0")"' <<<"$issues")
  for mark in "$RSTATE"/stale-*; do
    [[ -e $mark ]] || continue
    n=${mark##*/stale-}
    jq -e --argjson n "$n" 'any(.[]; .number == $n and any(.labels[].name; . == "agent:wip"))' <<<"$issues" >/dev/null ||
      rm -f "$mark"
  done

  if (( ${#EVENTS[@]} == 0 )) && [[ -z $busy ]] && [[ -z $(eligible_filter <<<"$issues") ]]; then
    blocked=$(jq -r '[.[] | select(any(.labels[].name; . == "agent:blocked")) | .number] | sort | join(",")' <<<"$issues")
    if [[ -n $blocked && $blocked != "$(cat "$RSTATE/idle" 2>/dev/null)" ]]; then
      echo "$blocked" >"$RSTATE/idle"
      EVENTS+=("idle $(tr ',' '\n' <<<"$blocked" | wc -l)")
    fi
  else
    rm -f "$RSTATE/idle"
  fi
}

main() {
  cd "$(git rev-parse --show-toplevel)"
  [[ -f $LOOP_REPO_CONFIG ]] || die 3 "$LOOP_REPO_CONFIG missing: repo is not enrolled"
  REPO=$(repo_slug)
  RSTATE=$(repo_state "$REPO")
  mkdir -p "$LOOP_STATE" "$RSTATE"/{results,pending}
  touch "$RSTATE/ledger.tsv"
  [[ ${1:-} == --status ]] && { status; exit 0; }
  local interval
  interval=$(fm_get "$LOOP_USER_CONFIG" poll_interval); interval=${interval:-60}
  while :; do
    poll_once
    if (( ${#EVENTS[@]} )); then printf '%s\n' "${EVENTS[@]}"; exit 0; fi
    [[ ${1:-} == --once ]] && exit 0
    sleep "$interval"
  done
}

main "$@"
