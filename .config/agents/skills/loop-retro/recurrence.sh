#!/usr/bin/env bash
# Summarize earlier retro proposals across all repos: one line per (target, cause)
# with its count, repos, and latest summaries. Read-only.
# Usage: recurrence.sh [TARGET-SUBSTRING]
set -euo pipefail
LOOP_STATE="${LOOP_STATE:-$HOME/.local/state/agent-loop}"
shopt -s nullglob
files=("$LOOP_STATE"/*/improvements.tsv)
(( ${#files[@]} )) || { echo "no earlier proposals"; exit 0; }
for f in "${files[@]}"; do
  repo=${f%/improvements.tsv}; repo=${repo##*/}
  awk -F'\t' -v repo="$repo" 'NF >= 5 { print repo "\t" $0 }' "$f"
done | awk -F'\t' -v want="${1:-}" '
  index($4, want) {
    k = $4 "\t" $5; n[k]++
    if (index(repos[k], $1) == 0) repos[k] = repos[k] (repos[k] ? "," : "") $1
    s[k] = "#" $3 " " $6 (s[k] ? " | " s[k] : "")
  }
  END { for (k in n) printf "%d\t%s\t%s\t%s\n", n[k], k, repos[k], substr(s[k], 1, 300) }' |
  sort -rn
