#!/usr/bin/env bash
# SessionStart hook: symlink .env and run direnv allow if we're in a worktree.

set -euo pipefail

input=""
if read -t 2 -r -d '' input; then :; fi

cwd="$(echo "$input" | jq -r '.cwd // empty')"
[[ -z "$cwd" ]] && exit 0

toplevel="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)" || exit 0
original_repo="$(git -C "$cwd" worktree list --porcelain | head -1 | sed 's/^worktree //')"
[[ "$original_repo" == "$toplevel" ]] && exit 0  # main checkout, possibly a subdirectory of it

if [[ -f "$original_repo/.env" && ! -e "$toplevel/.env" ]]; then
  ln -s "$original_repo/.env" "$toplevel/.env"
fi

if command -v direnv &>/dev/null && (cd "$original_repo" && direnv status --json 2>/dev/null | jq -e '.state.foundRC.allowed == 0' &>/dev/null); then
  direnv allow "$toplevel"
fi

cat <<'RULE'
Worktree-isolated session: a guard statically parses every Bash command and
refuses anything it cannot prove stays inside the worktree. It refuses on
"cannot prove", not on "found git" — compound commands fail even with no git
in them. One operation per Bash call: no ;, &&, heredocs, pipes into files, or
$VAR as a command argument. Expand the variable and use the literal path.
RULE
