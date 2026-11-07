#!/usr/bin/env bash
# SessionStart hook: sync the ledger, link the project's memory, and show its open items.
# Silent outside ~/Code/<host>/<group>/<repo>. Never fails the session.
. "$(dirname "$(readlink -f "$0")")/lib.sh"
cwd=$(jq -r '.cwd // empty' 2>/dev/null)
proj=$(ledger_project "${cwd:-$PWD}") || exit 0
notes=()
if [[ ! -d $LEDGER_ROOT/.git ]]; then
  notes+=("Ledger not found at $LEDGER_ROOT; clone ssh://git@code.segfault.me/alxbl/ledger.git there.")
else
  timeout 10 git -C "$LEDGER_ROOT" pull --rebase --autostash -q >/dev/null 2>&1 \
    || notes+=("Ledger pull failed or timed out; the registry below may be stale.")
  msg=$(ledger_link_memory "${cwd:-$PWD}" "$proj") && [[ -n $msg ]] && notes+=("$msg")
fi
section=$(ledger_registry_section "$proj")
ctx="Project $proj. Bookkeeping lives in $LEDGER_ROOT: follow the ledger skill (plans there, update REGISTRY.md when a task is added, started, blocked or done)."
((${#notes[@]})) && ctx+=$'\n'$(printf '%s\n' "${notes[@]}")
ctx+=$'\n\n'${section:-"(no open items recorded for $proj)"}
jq -n --arg c "$ctx" '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$c}}'
