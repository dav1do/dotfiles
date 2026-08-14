#!/usr/bin/env bash
set -euo pipefail

# @lastpane is set by the pane-focus-in hook. Killing a pane fires that hook too,
# so the id is often dead by now — check it before switching.

client=${1:-}
target=$(tmux show-option -gqv @lastpane)

[[ -n $target ]] || exit 0
tmux list-panes -a -F '#{pane_id}' | grep -qxF "$target" || exit 0

if [[ -n $client ]]; then
  tmux switch-client -c "$client" -Zt "$target"
else
  tmux switch-client -Zt "$target"
fi
