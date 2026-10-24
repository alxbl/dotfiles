#!/usr/bin/env bash
# Summarize earlier retro proposals across all enrolled repos: one line per (target, cause)
# with its count, repos, and latest summaries. Read-only.
# Usage: recurrence.sh [TARGET-SUBSTRING]
set -euo pipefail
LOOP_STATE="${LOOP_STATE:-$HOME/.local/state/agent-loop}"
[[ -s $LOOP_STATE/repos ]] || { echo "no earlier proposals"; exit 0; }
out=$(
while IFS=$'\t' read -r slug root; do
  f=$root/.agents/work/improvements.tsv
  [[ -s $f ]] || continue
  awk -F'\t' -v repo="$slug" 'NF >= 5 { print repo "\t" $0 }' "$f"
done < "$LOOP_STATE/repos" | awk -F'\t' -v want="${1:-}" '
  index($4, want) {
    k = $4 "\t" $5; n[k]++
    if (index(repos[k], $1) == 0) repos[k] = repos[k] (repos[k] ? "," : "") $1
    s[k] = "#" $3 " " $6 (s[k] ? " | " s[k] : "")
  }
  END { for (k in n) printf "%d\t%s\t%s\t%s\n", n[k], k, repos[k], substr(s[k], 1, 300) }' |
  sort -rn)
echo "${out:-no earlier proposals}"
