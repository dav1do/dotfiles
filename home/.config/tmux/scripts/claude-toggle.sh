#!/usr/bin/env bash
set -euo pipefail

claude_pane=$(tmux list-panes -F '#{pane_id} #{pane_current_command}' \
  | awk '$2 == "claude" { print $1; exit }')

current_pane=$(tmux display-message -p '#{pane_id}')
current_path=$(tmux display-message -p '#{pane_current_path}')

if [[ -z "$claude_pane" ]]; then
  tmux split-window -h -l '35%' -c "$current_path" 'claude'
elif [[ "$claude_pane" == "$current_pane" ]]; then
  tmux kill-pane -t "$claude_pane"
else
  tmux select-pane -t "$claude_pane"
fi
