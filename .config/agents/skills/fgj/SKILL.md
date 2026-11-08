---
name: fgj
description: Use fgj, the gh-compatible CLI for Forgejo, for issues, pull requests, CI runs, releases and the raw API on a Forgejo instance (for example code.segfault.me). Use it instead of gh whenever the git remote is not GitHub, and when porting a gh command or script to Forgejo.
---

# fgj

`fgj` is `gh` for Forgejo: same commands, flags, `--json` field names, `--jq` and exit codes wherever Forgejo allows. A repository on `github.com` uses `gh`; anything on a Forgejo host uses `fgj`. Never point `gh` at a Forgejo host.

Source of truth: `fgj --help`, `fgj <command> --help` (flags Forgejo cannot honour are listed there and exit 3) and `README.agent.md` in `code.segfault.me/alxbl/fgj`. Read them instead of trusting this summary for flags. The installed binary can lag the source: check `fgj --version` before relying on a new flag, and never judge a behaviour from a stale build.

## Working non-interactively

- Off a terminal fgj never prompts. Pass every input as a flag: `--title`, `--body`/`--body-file -`, a merge strategy (`--merge|--squash|--rebase`), and `--yes` for anything destructive.
- Credentials: `FORGEJO_TOKEN` or `fgj auth login --with-token` from stdin. Never put a token on a command line. With `FORGEJO_HOST` set, the token is sent to that host only.
- Pick the repository with `-R [HOST/]OWNER/REPO` or `FORGEJO_REPO` when the clone's remotes are ambiguous or use an SSH alias (fgj does not resolve aliases). `fgj repo set-default` pins one.
- List a command's JSON fields with `--json` and no fields. `--jq` is built in (no `jq` needed). Off a terminal output is compact JSON with sorted keys and tab-separated text with no header.
- `fgj api PATH` reaches anything without a command. Paths are relative to `/api/v1/`; `{owner}`, `{repo}` and `{branch}` are filled in.

## Exit codes

`0` ok, `1` failure, `2` cancelled, `3` not supported on Forgejo (the message says why; do not retry), `4` authentication, `8` pending (`pr checks`, `run view --exit-status`).

## Traps

- **No checks right after a push.** `fgj pr checks` can say "no checks reported" for a few seconds until the runs register, and `--watch` does not wait for checks that do not exist yet. Retry before concluding CI did not start.
- **Run IDs.** `run view|watch|rerun|cancel|delete` take the run's `databaseId` (`fgj run list --json databaseId`) or the run's full URL, never the bare number from an Actions URL (`.../actions/runs/50`): that reports "resource does not exist".
- **`pr create` does not push** unless you pass `--push` (an fgj flag, not in gh). Without it, push first or name an existing head with `--head [owner:]branch`.
- **Drafts are a `WIP:` title prefix.** `--draft`, `pr ready` and `pr ready --undo` edit the title. An instance with another prefix setting will not undraft.
- **Checks are commit statuses.** `pr checks --required` lists only the contexts the base branch's protection requires; a context nothing reported yet counts as pending (exit 8). Job logs are `fgj run view --log|--log-failed`.
- **Rerun failed jobs** with `fgj run rerun ID --failed`. A job that dies in under a second is a runner problem; rerun it.
- **Merging.** `pr merge ID --rebase --match-head-commit SHA` guards against a moved head. A bare "405" or "500" from the server is often a refused precondition (unresolved checks, protection, conflicts, a duplicate or circular dependency), not a server fault; check the cause before retrying.
- **`release create` pushes nothing.** It needs an existing tag or `--target`; without a tag it is an error (gh prompts). With files the release stays a draft until every upload finishes.
- **Search takes Forgejo keywords**, not GitHub qualifiers (`is:open author:x`). Use the flags.
- **Raw API errors:** the body goes to stdout and the message to stderr, exit 1 (4 for HTTP 401). A 403 usually means the token lacks a scope; `fgj auth status` shows the server version.
- **`--template` numbers are `float64`,** as in gh: `{{eq .number 1.0}}`, not `1`. Only a subset of Go templates is supported; the rest exits 3.

## Differences from gh

- Reviewers are logins or `ORG/TEAM`; `ORG` must be the organization that owns the repository.
- `fgj api graphql` is unsupported (exit 3). Projects, discussions, gists, codespaces, rulesets, merge queues, issue types, sub-issues, close reasons and `pr revert` do not exist.
- `--latest`, `--generate-notes` and `file#label` on releases exit 3; secrets and variables act on a repository (`--org`, and `--user` for secrets), never on environments.
- Workflows are files in `.forgejo/workflows` (else `.gitea`, `.github`); `workflow enable|disable` have no API; a workflow's `state` is always `active`; a run has no attempt number.
- `fgj status` has no `--json`; `fgj config` uses `--hostname` where gh uses `-h`.
- One account per host. `auth refresh` and `--clipboard` do not exist; OAuth tokens refresh themselves.
- Forgejo 17 is the target. Commands needing newer routes (`run cancel|rerun|delete`, `run view --verbose|--log`, `run download`, `issue lock`) exit 3 on Forgejo 15.
- Reactions can be read (`--json reactionGroups`) but not added or removed. Attachments are uploaded with `--attach FILE`; there is no command to list, download or delete them.

## When fgj cannot do something

Exit 3 means Forgejo or fgj lacks it. Try `fgj api` against the REST route (the instance serves its spec at `/api/swagger`) before giving up, and say plainly if the route does not exist. Known Forgejo-side gaps are tracked as issues in `code.segfault.me/alxbl/fgj`.
