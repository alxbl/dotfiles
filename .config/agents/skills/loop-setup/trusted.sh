#!/usr/bin/env bash
# Print GitHub issue or PR content written by trusted users only, as JSON. Roles read issue and
# PR text through this script instead of `gh`, so text from anyone else never reaches them.
# Run from inside an enrolled repo.
# Usage: trusted.sh issue N      the item (title, body), or a notice that its author is untrusted
#        trusted.sh comments N   trusted users' comments, and for a PR their reviews and review comments
set -euo pipefail
here=$(dirname "$(readlink -f "$0")")
# shellcheck source=lib.sh
source "$here/lib.sh"

require_trusted || exit 3
mode=${1:?issue|comments} n=${2:?number}
[[ $n =~ ^[0-9]+$ ]] || die 2 "not a number: $n"
api() { gh api --paginate "repos/{owner}/{repo}/$1" | jq -s 'add // []'; }

case $mode in
  issue)
    gh api "repos/{owner}/{repo}/issues/$n" | jq -s '.' | trusted_only |
      jq --argjson n "$n" 'if length == 0 then {number: $n, withheld: "author is not a trusted user"}
        else .[0] | {number, title, body, author: .user.login} end' ;;
  comments)
    pr=$(gh api "repos/{owner}/{repo}/issues/$n" | jq 'has("pull_request")')
    {
      api "issues/$n/comments" | trusted_only | jq 'map({source: "comment", author: .user.login, at: .created_at, body})'
      if [[ $pr == true ]]; then
        api "pulls/$n/reviews" | trusted_only | jq 'map({source: "review", author: .user.login, at: .submitted_at, body})'
        api "pulls/$n/comments" | trusted_only | jq 'map({source: "review-comment", author: .user.login, at: .created_at, body})'
      fi
    } | jq -s 'add | sort_by(.at)' ;;
  *) die 2 "usage: trusted.sh issue|comments N" ;;
esac
