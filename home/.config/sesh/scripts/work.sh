#!/usr/bin/env bash
# work — spin up my three ukon sessions (one window each) and attach to ukon.
# Idempotent: re-running just attaches; it won't clobber live sessions.
# List order = picker order top→bottom (when tmux sorts by index/creation).
set -euo pipefail

# name : path   (edit here to add/remove sessions)
sessions=(
  "ukon-core:$HOME/ukon/ukon-core"
  "ui:$HOME/ukon/ui"
  "ukon:$HOME/ukon"
)

for entry in "${sessions[@]}"; do
  name="${entry%%:*}"
  path="${entry#*:}"
  tmux has-session -t "=$name" 2>/dev/null \
    || tmux new-session -d -s "$name" -c "$path"
done

target="ukon"
if [ -n "${TMUX:-}" ]; then
  tmux switch-client -t "=$target"
  if [ "$(tmux display-message -p '#S')" = "dev" ]; then
    tmux kill-session -t "=dev"
  fi
else
  tmux attach-session -t "=$target"
fi
