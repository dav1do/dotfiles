#!/usr/bin/env bash
# Claude Code status line
input=$(cat)

# Dump full JSON for inspection
echo "$input" | jq '.' > /tmp/claude-statusline-debug.json

# ANSI colors
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
RESET='\033[0m'
DIM='\033[2m'
BRIGHT_WHITE='\033[0;97m'
BOLD_WHITE='\033[1;97m'
BOLD_CYAN='\033[1;96m'

model=$(echo "$input" | jq -r '.model.display_name // "unknown"')
model_id=$(echo "$input" | jq -r '.model.id // ""')
# Compute used_pct from current_usage.input_tokens / context_window_size so it
# reflects the current model's window size even after a mid-session model switch.
# The pre-calculated used_percentage field can be stale when the model changes.
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
ctx_input=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // empty')
if [ -n "$ctx_size" ] && [ -n "$ctx_input" ] && [ "$ctx_size" -gt 0 ]; then
  used_pct=$(awk "BEGIN{printf \"%.1f\", ($ctx_input/$ctx_size)*100}")
else
  used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
fi
session_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
session_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_resets=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
total_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
worktree_name=$(echo "$input" | jq -r '.worktree.name // empty')
worktree_branch=$(echo "$input" | jq -r '.worktree.branch // empty')

# Pick color based on a percentage value (0-100)
pct_color() {
  local pct=$1
  if awk "BEGIN{exit !($pct >= 80)}"; then
    printf '%s' "$RED"
  elif awk "BEGIN{exit !($pct >= 50)}"; then
    printf '%s' "$YELLOW"
  else
    printf '%s' "$GREEN"
  fi
}

# Render a block bar: e.g. "▓▓▓░░░░░░░" (10 chars wide)
bar() {
  local pct=$1
  local width=10
  local filled=$(awk "BEGIN{printf \"%d\", ($pct/100)*$width+0.5}")
  local empty=$(( width - filled ))
  local bar=""
  local i
  for (( i=0; i<filled; i++ )); do bar="${bar}▓"; done
  for (( i=0; i<empty; i++ )); do  bar="${bar}░"; done
  printf '%s' "$bar"
}

# Format seconds into human-readable countdown: "2h30m", "3d4h", "45m", etc.
fmt_countdown() {
  local secs=$1
  if [ "$secs" -le 0 ]; then
    printf 'now'
    return
  fi
  local days=$(( secs / 86400 ))
  local hours=$(( (secs % 86400) / 3600 ))
  local mins=$(( (secs % 3600) / 60 ))
  if [ "$days" -gt 0 ]; then
    printf '%dd%dh' "$days" "$hours"
  elif [ "$hours" -gt 0 ]; then
    printf '%dh%dm' "$hours" "$mins"
  else
    printf '%dm' "$mins"
  fi
}


BLUE='\033[0;34m'
BOLD_YELLOW='\033[1;33m'

parts=()

# Model (bright white bold)
parts+=("$(printf "${BOLD_CYAN}%s${RESET}" "$model")")

# Location: folder + git branch + worktree
if [ -n "$cwd" ]; then
  folder=$(basename "$cwd")
  loc_str="$(printf "${BLUE}%s${RESET}" "$folder")"
  # Git branch (skip optional locks, read HEAD directly)
  git_dir=$(git -C "$cwd" rev-parse --git-dir 2>/dev/null)
  if [ -n "$git_dir" ]; then
    branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
      loc_str="${loc_str}$(printf "${DIM}:${RESET}${BOLD_YELLOW}%s${RESET}" "$branch")"
    fi
  fi
  # Worktree indicator
  if [ -n "$worktree_name" ]; then
    wt_label="${worktree_name}"
    [ -n "$worktree_branch" ] && wt_label="${worktree_branch}"
    loc_str="${loc_str}$(printf "${DIM}[wt:%s]${RESET}" "$wt_label")"
  fi
  parts+=("$loc_str")
fi

# Context window with colored bar
if [ -n "$used_pct" ]; then
  color=$(pct_color "$used_pct")
  b=$(bar "$used_pct")
  parts+=("$(printf "${DIM}ctx:${RESET}${color}%s${RESET}" "$b")")
fi

# Session token totals (input + output)
if [ -n "$session_in" ] && [ -n "$session_out" ]; then
  total=$(( session_in + session_out ))
  if [ "$total" -ge 1000000 ]; then
    fmt=$(awk "BEGIN{printf \"%.2fM\", $total/1000000}")
  elif [ "$total" -ge 100000 ]; then
    fmt=$(awk "BEGIN{printf \"%.0fk\", $total/1000}")
  elif [ "$total" -ge 10000 ]; then
    fmt=$(awk "BEGIN{printf \"%.1fk\", $total/1000}")
  elif [ "$total" -ge 1000 ]; then
    fmt=$(awk "BEGIN{printf \"%.2fk\", $total/1000}")
  else
    fmt="$total"
  fi
  parts+=("$(printf "${DIM}sess:${RESET}${BRIGHT_WHITE}%s${RESET}" "$fmt")")
fi

# Session (5h) rate limit with reset countdown
if [ -n "$five_pct" ]; then
  color=$(pct_color "$five_pct")
  label="$(printf "${DIM}5h:${RESET}${color}%.0f%%${RESET}" "$five_pct")"
  if [ -n "$five_resets" ]; then
    now=$(date +%s)
    remaining=$(( five_resets - now ))
    countdown=$(fmt_countdown "$remaining")
    label="${label}$(printf "${DIM}(%s)${RESET}" "$countdown")"
  fi
  parts+=("$label")
fi

# Weekly (7d) rate limit with reset countdown
if [ -n "$week_pct" ]; then
  color=$(pct_color "$week_pct")
  label="$(printf "${DIM}7d:${RESET}${color}%.0f%%${RESET}" "$week_pct")"
  if [ -n "$week_resets" ]; then
    now=$(date +%s)
    remaining=$(( week_resets - now ))
    countdown=$(fmt_countdown "$remaining")
    label="${label}$(printf "${DIM}(%s)${RESET}" "$countdown")"
  fi
  parts+=("$label")
fi

# Actual cumulative cost from API
if [ -n "$total_cost" ]; then
  cost=$(awk "BEGIN{printf \"\$%.2f\", $total_cost}")
  parts+=("$(printf "${DIM}cost:${RESET}${BRIGHT_WHITE}%s${RESET}" "$cost")")
fi

# Join with dim separator
sep="$(printf "${DIM}|${RESET}")"
result=""
for part in "${parts[@]}"; do
  if [ -z "$result" ]; then
    result="$part"
  else
    result="${result}${sep}${part}"
  fi
done
printf "%s" "$result"
