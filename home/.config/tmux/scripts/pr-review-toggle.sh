#!/usr/bin/env bash
# prefix+W: jump to the PR review watcher, starting it if nothing holds it.
# The watcher itself takes a lockdir, so this only has to find the window that
# already owns it — a second one would exit with "already watching".
set -euo pipefail

WIN=pr-watch

# --run is what the window actually executes; ^C and a clean stop close it, and
# only a real failure (bad lock, gh auth) holds the window open to be read.
if [[ ${1:-} == --run ]]; then
  bash ~/.local/bin/pr-review-watch.sh --watch
  rc=$?
  if [[ $rc -ne 0 && $rc -ne 130 ]]; then
    printf '\n[watcher exited rc %s] enter to close' "$rc"
    read -r _
  fi
  exit 0
fi

client=${1:-}

target=$(tmux list-windows -a -F '#{session_name}:#{window_index} #{window_name}' \
  | awk -v w="$WIN" '$2 == w { print $1; exit }')

if [[ -n $target ]]; then
  # -c matters: run-shell has no client of its own, same reason last-pane.sh takes one.
  if [[ -n $client ]]; then
    tmux switch-client -c "$client" -t "$target"
  else
    tmux switch-client -t "$target"
  fi
  exit 0
fi

tmux new-window -n "$WIN" "bash ~/.config/tmux/scripts/pr-review-toggle.sh --run"
