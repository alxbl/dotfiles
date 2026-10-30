# Shared helpers for the agent loop scripts. Source it; do not execute.
# Assumes the current directory is the root of an enrolled repo and `gh` is authenticated.

LOOP_STATE="${LOOP_STATE:-$HOME/.local/state/agent-loop}"
LOOP_USER_CONFIG="${LOOP_USER_CONFIG:-$HOME/.config/agents/loop.md}"
LOOP_SKILLS_DIR="${LOOP_SKILLS_DIR:-$HOME/.claude/skills}"
LOOP_ROLES=(eval explore plan contribute review retro)
LOOP_REPO_CONFIG=".agents/loop.md"
LOOP_REPO_SETTINGS=".agents/settings.json"
LOOP_STATES=(agent:explore agent:explored agent:planned agent:review agent:changes agent:human-review agent:blocked)
LOOP_WORK=".agents/work"

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

# Print the `validate` entries of the repo config, one per line.
validate_commands() {
  [[ -f $LOOP_REPO_CONFIG ]] || return 0
  awk '
    NR == 1 { if ($0 != "---") exit; next }
    $0 == "---" { exit }
    /^validate:/ { on = 1; next }
    on && /^[ \t]+- / { v = $0; sub(/^[ \t]+- /, "", v); gsub(/^["\x27]|["\x27]$/, "", v); print v; next }
    on && !/^[ \t]/ { on = 0 }' "$LOOP_REPO_CONFIG"
}

# Print each `validate` entry that no Bash allow rule in the repo settings covers, or that is a
# compound command (which no rule matches). `<placeholders>` stand for any word; text after
# " when " or ", " is prose.
validate_unmatched() {
  local entry cmd rule rules ok
  mapfile -t rules < <(jq -r '.permissions.allow[]? | select(startswith("Bash(")) | .[5:-1]' "$LOOP_REPO_SETTINGS" 2>/dev/null)
  while IFS= read -r entry; do
    [[ -n $entry ]] || continue
    cmd=$(sed -E 's/<[^>]*>/x/g; s/( when |, ).*$//' <<<"$entry")
    ok=
    if [[ $cmd != *[\;\|\>\&]* ]]; then
      for rule in "${rules[@]}"; do
        if [[ $rule == *:\* ]]; then [[ $cmd == "${rule%:\*}" || $cmd == "${rule%:\*} "* ]] && ok=1
        else [[ $cmd == $rule ]] && ok=1; fi
      done
    fi
    [[ -n $ok ]] || printf '%s\n' "$entry"
  done < <(validate_commands)
}

# Print setting KEY: repo config, then user config, then DEFAULT.
cfg() {
  local v
  v=$(fm_get "$LOOP_REPO_CONFIG" "$1")
  [[ -n $v ]] || v=$(fm_get "$LOOP_USER_CONFIG" "$1")
  echo "${v:-$2}"
}

# Print the item's eval KEY (complexity: trivial|standard|complex, security: yes|no), or nothing
# when the eval is missing or the value is not one of those.
eval_get() {
  local v
  v=$(sed -n "s/^$2=//p" "$(item_dir "$1")/eval.md" 2>/dev/null | head -n1)
  case $2=$v in
    complexity=trivial | complexity=standard | complexity=complex | security=yes | security=no) echo "$v" ;;
  esac
}

# Print the model for ROLE on item ITEM. An explicit model_<role> setting wins; otherwise the
# item's eval decides, never below sonnet except for eval itself and a trivial contribute.
# Contribute is never opus. Retro uses opus unless the eval ruled out security impact.
role_model() {
  local v c s
  v=$(cfg "model_$1" "")
  [[ -z $v ]] || { echo "$v"; return; }
  c=$(eval_get "$2" complexity); s=$(eval_get "$2" security)
  case $1 in
    eval) echo haiku ;;
    contribute) [[ $c == trivial ]] && echo haiku || echo sonnet ;;
    retro) [[ $s == no ]] && echo sonnet || echo opus ;;
    *) [[ $c == complex ]] && echo opus || echo sonnet ;;
  esac
}

# Print the tool patterns ROLE may not use, one per line, for the repo at ROOT. Only
# contribute writes code. Paths are absolute because relative rules follow the Bash
# tool's working directory, which moves when a role runs `cd` into a worktree.
role_disallowed() {
  [[ $1 == contribute ]] || printf '%s\n' "Edit(/$2/.worktrees/**)" "Write(/$2/.worktrees/**)" NotebookEdit
}

# Print the file-edit patterns ROLE is allowed, one per line, for the repo at ROOT.
role_allowed() {
  local t
  for t in Edit Write; do
    printf '%s\n' "$t(/$2/$LOOP_WORK/**)"
    [[ $1 != contribute ]] || printf '%s\n' "$t(/$2/.worktrees/**)"
  done
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

# Print the root of the main checkout of the current repo.
repo_root() { dirname "$(realpath "$(git rev-parse --git-common-dir)")"; }

# Print the loop's working directory for the current repo. All loop context lives here.
repo_state() { echo "$(repo_root)/$LOOP_WORK"; }

# Print the directory holding the context of issue N.
item_dir() { echo "$(repo_state)/$1"; }

# Keep the working directory and the code worktrees out of git, and record the
# repo (SLUG) so cross-repo tools can find its context.
init_work() {
  local slug=$1 ex tmp p
  ex="$(realpath "$(git rev-parse --git-common-dir)")/info/exclude"
  mkdir -p "$(dirname "$ex")" "$(repo_state)" "$LOOP_STATE"
  for p in "$LOOP_WORK/" .worktrees/; do grep -qxF "$p" "$ex" 2>/dev/null || echo "$p" >>"$ex"; done
  tmp=$(mktemp)
  { grep -v "^$slug"$'\t' "$LOOP_STATE/repos" 2>/dev/null || true; printf '%s\t%s\n' "$slug" "$(repo_root)"; } >"$tmp"
  mv "$tmp" "$LOOP_STATE/repos"
}

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

# Print the GitHub user ids whose issues and comments the loop may act on, comma-separated.
# Only the user config is read: a repo must not be able to widen its own trust.
trusted_ids() { fm_get "$LOOP_USER_CONFIG" trusted_user_ids | tr -d '[:space:]'; }

# Succeed if the user config names at least one trusted user id; otherwise explain and fail.
require_trusted() { [[ -n $(trusted_ids) ]] || { echo "trusted_user_ids is not set in $LOOP_USER_CONFIG" >&2; return 1; }; }

# Read a GitHub REST object or array on stdin; keep the entries whose .user is a trusted
# human account. Matches the immutable numeric id and the account type, never the login.
trusted_only() {
  jq --argjson ids "[$(trusted_ids)]" 'map(select(.user.type == "User" and (.user.id as $i | $ids | index($i))))'
}

# Print open issues (not PRs) opened by a trusted user, as JSON: number, labels, createdAt.
list_issues() {
  gh api --paginate 'repos/{owner}/{repo}/issues?state=open&per_page=100' | jq -s 'add // []' |
    jq 'map(select(.pull_request | not))' | trusted_only |
    jq 'map({number, labels, createdAt: .created_at})'
}

# Read `list_issues` JSON on stdin; print eligible issue numbers in pickup order.
eligible_filter() {
  jq -r '
    def has($l): any(.labels[].name; . == $l);
    def rank:
      if has("agent:changes") then 1
      elif has("agent:review") then 2
      elif has("agent:planned") then 3
      elif has("agent:explored") then 4
      elif has("agent:explore") then 5
      else 0 end;
    map(select((has("agent:wip") or has("agent:blocked")) | not) | .rank = rank | select(.rank > 0))
    | sort_by(.rank, .createdAt) | .[].number'
}

# Block issue N from STATE and record why in its blocked.md: block_item N SLOT STATE NEED RESUME.
# Needs RSTATE.
block_item() {
  local d
  d=$(item_dir "$1")
  mkdir -p "$d"
  printf '## %s loop:%s blocked this item\nat-round=%s\n**Needed:** %s\n**Resume:** %s\n\n' \
    "$(date -Is)" "$2" "$(find "$d" -maxdepth 1 -name 'review-*.md' | wc -l)" "$4" "$5" >>"$d/blocked.md"
  gh issue edit "$1" --add-label agent:blocked --remove-label "$3" >/dev/null
  ledger "$1" "$2" blocked "$3"
}

# Print the state label of issue N (see LOOP_STATES), or nothing.
item_state() {
  local labels s
  labels=$(gh issue view "$1" --json labels | jq -r '.labels[].name')
  for s in agent:blocked agent:human-review agent:changes agent:review agent:planned agent:explored agent:explore; do
    grep -qxF "$s" <<<"$labels" && { echo "$s"; return; }
  done
}

# Print the number of the PR that implements issue N, or nothing.
find_pr() { cat "$(item_dir "$1")/pr" 2>/dev/null || true; }

# Print how many review rounds of issue N asked for changes since the last pass
# or block. Zero when there is no PR. Round r is review-<r>.md, whose first line is
# verdict=pass|changes; a block records at-round=<rounds so far> in blocked.md.
change_rounds() {
  local d total base=0 r n=0
  d=$(item_dir "$1")
  [[ -n $(find_pr "$1") ]] || { echo 0; return; }
  [[ -f $d/blocked.md ]] && base=$(sed -n 's/^at-round=//p' "$d/blocked.md" | tail -n1)
  base=${base:-0}
  total=$(find "$d" -maxdepth 1 -name 'review-*.md' 2>/dev/null | wc -l)
  for ((r = 1; r <= total; r++)); do
    [[ $(sed -n '1s/^verdict=//p' "$d/review-$r.md" 2>/dev/null) == pass ]] && (( r > base )) && base=$r
  done
  for ((r = base + 1; r <= total; r++)); do
    [[ $(sed -n '1s/^verdict=//p' "$d/review-$r.md" 2>/dev/null) == changes ]] && n=$((n + 1))
  done
  echo "$n"
}
