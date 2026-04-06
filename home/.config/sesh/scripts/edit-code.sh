#!/usr/bin/env bash

# Wait for direnv to load (it hooks into cd in zsh)
sleep 1

# Window 1: editor (current window)
tmux rename-window "editor"

# Window 2: two vertical panes (equal split)
tmux new-window -n "terminals"
clear
tmux split-window -h
clear
tmux select-layout even-horizontal

# Go back to editor window and start nvim (must be last, it blocks)
tmux select-window -t 0
nvim .
