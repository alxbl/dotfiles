#!/usr/bin/env bash
# Create or update the agent loop labels in the current repo. Idempotent.
set -euo pipefail
while IFS='|' read -r name color desc; do
  gh label create "$name" --color "$color" --description "$desc" --force >/dev/null
  echo "$name"
done <<'EOF'
agent:explore|C5DEF5|Approved for the agent loop; needs a spec
agent:explored|0E8A16|Spec ready; needs implementation
agent:review|FBCA04|PR open; awaiting agent review
agent:changes|D93F0B|Agent review asked for changes
agent:human-review|5319E7|Agent review passed; waiting for a human
agent:blocked|B60205|Needs a human; no loop will pick it up
agent:wip|EDEDED|An agent loop holds this item
EOF
