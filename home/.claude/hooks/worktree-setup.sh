#!/usr/bin/env bash
# SessionStart hook: symlink .env and run direnv allow if we're in a worktree.

set -euo pipefail

input=""
if read -t 2 -r -d '' input; then :; fi

cwd="$(echo "$input" | jq -r '.cwd // empty')"
[[ -z "$cwd" ]] && exit 0

# Only run in worktrees
if ! git -C "$cwd" rev-parse --is-inside-work-tree &>/dev/null; then exit 0; fi
original_repo="$(git -C "$cwd" worktree list --porcelain | head -1 | sed 's/^worktree //')"
[[ "$original_repo" == "$cwd" ]] && exit 0  # not a worktree, this is the main repo

# Symlink .env if it exists in the original repo
if [[ -f "$original_repo/.env" && ! -e "$cwd/.env" ]]; then
  ln -s "$original_repo/.env" "$cwd/.env"
fi

# Allow direnv if active in the original project
if command -v direnv &>/dev/null && (cd "$original_repo" && direnv status --json 2>/dev/null | jq -e '.state.foundRC.allowed == 0' &>/dev/null); then
  direnv allow "$cwd"
fi

echo "ok"
