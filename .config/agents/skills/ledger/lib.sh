#!/usr/bin/env bash
# Helpers for the ledger skill and hooks. Source it; it only defines functions.
LEDGER_ROOT=${LEDGER_ROOT:-$HOME/Code/code.segfault.me/alxbl/ledger/main}
LEDGER_CODE=${LEDGER_CODE:-$HOME/Code}
LEDGER_GROUP=${LEDGER_GROUP:-alxbl}
CLAUDE_PROJECTS=${CLAUDE_PROJECTS:-$HOME/.claude/projects}

# ledger_project DIR: print "<host>/<repo>" for a directory inside ~/Code/<host>/<group>/<repo>; fail elsewhere.
ledger_project() {
  [[ $1 == "$LEDGER_CODE"/* ]] || return 1
  local host group repo _
  IFS=/ read -r host group repo _ <<<"${1#"$LEDGER_CODE"/}"
  [[ $group == "$LEDGER_GROUP" && -n $repo ]] || return 1
  echo "$host/$repo"
}

# ledger_memory_key DIR: the directory name Claude Code uses under ~/.claude/projects.
ledger_memory_key() { printf '%s' "$1" | sed 's#[/.]#-#g'; }

# ledger_registry_section PROJECT: print that project's REGISTRY.md section.
ledger_registry_section() {
  awk -v h="## $1" '$0 == h { p = 1; print; next } /^## / { p = 0 } p' "$LEDGER_ROOT/REGISTRY.md" 2>/dev/null
}

# ledger_link_memory DIR PROJECT: make DIR's Claude memory directory a symlink into the ledger.
# Never replaces a non-empty directory; prints a message instead.
ledger_link_memory() {
  local mem dst=$LEDGER_ROOT/$2/memory
  mem=$CLAUDE_PROJECTS/$(ledger_memory_key "$1")/memory
  mkdir -p "$dst"
  if [[ -L $mem ]]; then
    [[ $(readlink "$mem") == "$dst" ]] || echo "memory link $mem points to $(readlink "$mem"), expected $dst"
  elif [[ -d $mem ]]; then
    rmdir "$mem" 2>/dev/null || { echo "memory dir $mem is not empty and was not linked; move its files into $dst"; return 0; }
    ln -s "$dst" "$mem"
  else
    mkdir -p "${mem%/*}" && ln -s "$dst" "$mem"
  fi
}
