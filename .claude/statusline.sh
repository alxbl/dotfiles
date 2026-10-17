#!/usr/bin/env bash
# Claude Code status line: model | ctx | dir | git branch | rate limits
input=$(cat)
j() { echo "$input" | jq -r "$1 // empty"; }

model=$(j '.model.display_name')
used=$(j '.context_window.used_percentage')
dir=$(j '.workspace.current_dir')
[ -z "$dir" ] && dir=$(j '.cwd')
short=${dir/#$HOME/\~}

out=$(printf '%s | ctx %.0f%%' "$model" "${used:-0}")
out="$out | $short"

branch=$(git -C "$dir" symbolic-ref --short HEAD 2>/dev/null || git -C "$dir" rev-parse --short HEAD 2>/dev/null)
[ -n "$branch" ] && out="$out |  $branch"

# Rate limits (only present for subscription plans, after the first response)
fmt_reset() {
  local ts=$1 now diff
  now=$(date +%s); diff=$((ts - now))
  [ "$diff" -le 0 ] && { echo "now"; return; }
  if [ "$diff" -ge 86400 ]; then printf '%dd%dh' $((diff/86400)) $((diff%86400/3600))
  else printf '%dh%02dm' $((diff/3600)) $((diff%3600/60)); fi
}
for w in five_hour:5h seven_day:7d; do
  key=${w%%:*}; label=${w##*:}
  pct=$(j ".rate_limits.$key.used_percentage")
  [ -z "$pct" ] && continue
  rs=$(j ".rate_limits.$key.resets_at")
  seg=$(printf '%s %.0f%%' "$label" "$pct")
  [ -n "$rs" ] && seg="$seg (resets in $(fmt_reset "$rs"))"
  out="$out | $seg"
done
printf '%s' "$out"
