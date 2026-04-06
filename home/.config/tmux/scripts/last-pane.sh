#!/usr/bin/env bash
# Tracks pane focus across windows/sessions and jumps back to the last one.
# Usage:
#   last-pane.sh track   — called by tmux hooks to record pane changes
#   last-pane.sh jump    — called by keybind to jump to previous pane

get_pane_id() {
  tmux display-message -p '#{session_name}:#{window_index}.#{pane_index}'
}

case "$1" in
  track)
    # If we're mid-jump, just clear the flag and don't update history
    jumping=$(tmux show-environment -g TMUX_JUMPING 2>/dev/null | cut -d= -f2)
    if [ "$jumping" = "1" ]; then
      tmux set-environment -g TMUX_JUMPING 0
      exit 0
    fi

    current=$(get_pane_id)
    saved=$(tmux show-environment -g TMUX_CURRENT_PANE 2>/dev/null | cut -d= -f2)

    # Only update LAST if we actually moved somewhere different
    if [ -n "$saved" ] && [ "$saved" != "$current" ]; then
      tmux set-environment -g TMUX_LAST_PANE "$saved"
    fi
    tmux set-environment -g TMUX_CURRENT_PANE "$current"
    ;;

  jump)
    target=$(tmux show-environment -g TMUX_LAST_PANE 2>/dev/null | cut -d= -f2)
    if [ -z "$target" ]; then
      tmux display-message "No previous pane to jump to"
      exit 0
    fi

    # Set guard flag so the hook doesn't treat the jump as a normal switch
    tmux set-environment -g TMUX_JUMPING 1

    # Save where we are now so we can toggle back
    current=$(get_pane_id)
    tmux set-environment -g TMUX_LAST_PANE "$current"
    tmux set-environment -g TMUX_CURRENT_PANE "$target"

    tmux switch-client -t "$target"
    ;;
esac
