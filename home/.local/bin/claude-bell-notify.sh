#!/bin/bash
# Sends a macOS notification when Claude Code is waiting for input.
# Called by Claude Code's Notification hook. Filters to idle_prompt only.

input=$(cat)
notification_type=$(echo "$input" | grep -o '"notification_type":"[^"]*"' | cut -d'"' -f4)

[ "$notification_type" != "idle_prompt" ] && exit 0

session=$(tmux display-message -p '#{session_name}' 2>/dev/null)
window=$(tmux display-message -p '#{window_name}' 2>/dev/null)

if [ -n "$session" ]; then
    osascript -e "display notification \"Session ${session} (${window}) needs you\" with title \"Claude Code\""
else
    osascript -e "display notification \"Claude needs your attention\" with title \"Claude Code\""
fi
