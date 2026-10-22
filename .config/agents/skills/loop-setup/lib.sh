# Shared helpers for the agent loop scripts. Source it; do not execute.
# Assumes the current directory is the root of an enrolled repo and `gh` is authenticated.

LOOP_STATE="${LOOP_STATE:-$HOME/.local/state/agent-loop}"
LOOP_USER_CONFIG="${LOOP_USER_CONFIG:-$HOME/.config/agents/loop.md}"
LOOP_REPO_CONFIG=".agents/loop.md"
LOOP_REPO_SETTINGS=".agents/settings.json"
LOOP_STATES=(agent:explore agent:explored agent:review agent:changes agent:human-review agent:blocked)

die() { local code=$1; shift; echo "$*" >&2; exit "$code"; }

# Print the YAML front-matter scalar KEY from FILE, or nothing.
fm_get() {
  local file=$1 key=$2
  [[ -f $file ]] || return 0
  awk -v key="$key" '
    NR == 1 { if ($0 != "---") exit; next }
    $0 == "---" { exit }
    index($0, key ":") == 1 {
      v = substr($0, length(key) + 2)
      sub(/^[ \t]+/, "", v); sub(/[ \t]+#.*$/, "", v); sub(/[ \t]+$/, "", v)
      gsub(/^["\x27]|["\x27]$/, "", v)
      print v; exit
    }' "$file"
}

# Print setting KEY: repo config, then user config, then DEFAULT.
cfg() {
  local v
  v=$(fm_get "$LOOP_REPO_CONFIG" "$1")
  [[ -n $v ]] || v=$(fm_get "$LOOP_USER_CONFIG" "$1")
  echo "${v:-$2}"
}

# Print the user-wide WIP limit (number of slots).
user_wip() { local v; v=$(fm_get "$LOOP_USER_CONFIG" wip); echo "${v:-1}"; }

# Print the WIP limit for this repo: the user limit, lowered by the repo config.
repo_wip() {
  local u r
  u=$(user_wip); r=$(fm_get "$LOOP_REPO_CONFIG" wip)
  if [[ -n $r ]] && (( r < u )); then echo "$r"; else echo "$u"; fi
}

repo_slug() { gh repo view --json nameWithOwner | jq -r .nameWithOwner; }

# Print the state directory for REPO (owner/name).
repo_state() { echo "$LOOP_STATE/${1/\//-}"; }

# Append one ledger line: ITEM SLOT EVENT DETAIL. Needs RSTATE.
ledger() { printf '%s\t%s\t%s\t%s\t%s\n' "$(date -Is)" "$1" "$2" "$3" "${4:-}" >>"$RSTATE/ledger.tsv"; }

# Succeed if slot N is held by a running loop.
slot_held() { [[ -e $LOOP_STATE/slot-$1.lock ]] && ! flock -n "$LOOP_STATE/slot-$1.lock" true; }

# Print the issue numbers of REPO held by running loops.
held_items() {
  local f n
  for f in "$LOOP_STATE"/slot-*.item; do
    [[ -e $f ]] || continue
    n=${f##*/slot-}; n=${n%.item}
    slot_held "$n" || continue
    sed -n "s|^$1#||p" "$f"
  done
}

# Print the number of free slots.
free_slots() {
  local n free=0
  for ((n = 1; n <= $(user_wip); n++)); do slot_held "$n" || free=$((free + 1)); done
  echo "$free"
}

list_issues() { gh issue list --state open --limit 500 --json number,labels,createdAt; }

# Read `list_issues` JSON on stdin; print eligible issue numbers in pickup order.
eligible_filter() {
  jq -r '
    def has($l): any(.labels[].name; . == $l);
    def rank:
      if has("agent:changes") then 1
      elif has("agent:review") then 2
      elif has("agent:explored") then 3
      elif has("agent:explore") then 4
      else 0 end;
    map(select((has("agent:wip") or has("agent:blocked")) | not) | .rank = rank | select(.rank > 0))
    | sort_by(.rank, .createdAt) | .[].number'
}

# Print the state label of issue N (see LOOP_STATES), or nothing.
item_state() {
  local labels s
  labels=$(gh issue view "$1" --json labels | jq -r '.labels[].name')
  for s in agent:blocked agent:human-review agent:changes agent:review agent:explored agent:explore; do
    grep -qxF "$s" <<<"$labels" && { echo "$s"; return; }
  done
}

# Print the number of the open PR that implements issue N, or nothing.
find_pr() {
  gh pr list --state open --limit 200 --json number,body |
    jq -r --arg m "<!-- loop:pr issue=$1 -->" 'map(select(.body | contains($m))) | .[0].number // empty'
}

# Print how many review rounds on issue N's PR asked for changes since the last
# block or pass. Zero when there is no PR.
change_rounds() {
  local pr since
  pr=$(find_pr "$1")
  [[ -n $pr ]] || { echo 0; return; }
  since=$(gh issue view "$1" --json comments |
    jq -r '[.comments[] | select(.body | contains("<!-- loop:blocked -->")) | .createdAt] | max // ""')
  gh pr view "$pr" --json comments | jq -r --arg since "$since" '
    [.comments[] | select(.body | test("<!-- loop:review round=[0-9]+ verdict=")) ] as $r
    | ([$r[] | select(.body | contains("verdict=pass")) | .createdAt] | max // "") as $pass
    | ([$since, $pass] | max) as $after
    | [$r[] | select(.body | contains("verdict=changes")) | select(.createdAt > $after)] | length'
}
