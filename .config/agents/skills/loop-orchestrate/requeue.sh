#!/usr/bin/env bash
# Release the stale claim of issue N held by SLOT. The first time the item is requeued;
# a second stale claim blocks it. Prints "requeued" or "blocked". Run from inside an enrolled repo.
# Usage: requeue.sh N SLOT
set -euo pipefail
here=$(dirname "$(readlink -f "$0")")
# shellcheck source=../loop-setup/lib.sh
source "$here/../loop-setup/lib.sh"

n=${1:?issue number} slot=${2:?slot}
cd "$(git rev-parse --show-toplevel)"
RSTATE=$(repo_state)
mkdir -p "$RSTATE"
gh issue edit "$n" --remove-label agent:wip --remove-label "loop:$slot" >/dev/null
if awk -F'\t' -v n="$n" '$2 == n && $4 == "requeue" { f = 1 } END { exit !f }' "$RSTATE/ledger.tsv" 2>/dev/null; then
  block_item "$n" "$slot" "$(item_state "$n")" \
    "The claim on this item went stale twice: its loop died without finishing. Check the logs in \`$(item_dir "$n")/logs\`." \
    "Fix the cause, then remove \`agent:blocked\` and set the state label again."
  echo blocked
else
  ledger "$n" - requeue
  echo requeued
fi
