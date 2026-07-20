#!/usr/bin/env bash
# Claude Code status line.
# Runs locally in the client on each render — consumes ZERO model tokens; it only
# reads the transcript file and prints. Process spawns are kept minimal: two jq
# calls (stdin JSON + transcript JSONL) and at most one git call. All numeric
# formatting/thresholds are done in jq or pure-bash integer math — no awk, no
# date(1), no basename(1). Colors are real ESC bytes (see $'...' below), so fields
# are built by plain string interpolation and emitted with a single printf.
input=$(cat)

# Dump full JSON for inspection
# echo "$input" | jq '.' > /tmp/claude-statusline-debug.json

# ANSI colors — ANSI-C quoting ($'...') yields actual ESC bytes, not literal
# backslash text, so no printf is needed to interpret them.
RED=$'\033[0;31m'
YELLOW=$'\033[0;33m'
GREEN=$'\033[0;32m'
RESET=$'\033[0m'
DIM=$'\033[2m'
BRIGHT_WHITE=$'\033[0;97m'
BOLD_WHITE=$'\033[1;97m'
BOLD_CYAN=$'\033[1;96m'
MAGENTA=$'\033[0;35m'
CYAN=$'\033[0;36m'
BLUE=$'\033[0;34m'
BOLD_YELLOW=$'\033[1;33m'

# --- jq call #1: pull + preformat every line-1 field from stdin JSON as one row ---
# jq does the float formatting bash can't (fixed-decimal %, cost cents), and emits
# a floor()'d int alongside each percentage so bash can pick a threshold color with
# plain integer compares (faithful to the old raw-value awk compares, since the
# thresholds are integers). Absent fields become "" so the [ -n ] guards still work.
# Delimit with \x1f (unit separator), NOT tab: bash `read` collapses consecutive
# IFS-whitespace (tab included), which would drop empty fields and shift the rest.
QUERY='
  def f1(v): if v==null then "" else (v*10|round) as $t | ($t/10|floor) as $w | "\($w).\($t-$w*10)" end;
  def f0(v): if v==null then "" else (v|round|tostring) end;
  def fl(v): if v==null then "" else (v|floor|tostring) end;
  def s(v):  if v==null then "" else (v|tostring) end;
  [ (.model.display_name // "unknown"),
    f1(.context_window.used_percentage),
    fl(.context_window.used_percentage),
    f0(.rate_limits.five_hour.used_percentage),
    fl(.rate_limits.five_hour.used_percentage),
    s(.rate_limits.five_hour.resets_at),
    f0(.rate_limits.seven_day.used_percentage),
    fl(.rate_limits.seven_day.used_percentage),
    s(.rate_limits.seven_day.resets_at),
    (if .cost.total_cost_usd==null then "" else (.cost.total_cost_usd*100|round|tostring) end),
    s(.cost.total_lines_added),
    s(.cost.total_lines_removed),
    (.workspace.current_dir // .cwd // ""),
    s(.worktree.name),
    s(.worktree.branch),
    s(.transcript_path)
  ] | join("")'

IFS=$'\x1f' read -r model used_disp used_int five_disp five_int five_resets \
  week_disp week_int week_resets cost_cents lines_added lines_removed \
  cwd worktree_name worktree_branch transcript \
  < <(printf '%s' "$input" | jq -r "$QUERY")

# Pick color for a percentage (0-100 int): high is BAD (usage meters). Sets REPLY.
pct_color() {
  local p=$1
  if   [ "$p" -ge 80 ]; then REPLY=$RED
  elif [ "$p" -ge 50 ]; then REPLY=$YELLOW
  else REPLY=$GREEN; fi
}

# Inverted: high is GOOD (cache hit rate) — green high, red low. Sets REPLY.
pct_color_inv() {
  local p=$1
  if   [ "$p" -ge 70 ]; then REPLY=$GREEN
  elif [ "$p" -ge 40 ]; then REPLY=$YELLOW
  else REPLY=$RED; fi
}

# Humanize an integer token count: 1234 -> 1k, 31553 -> 32k, 3428579 -> 3.4M.
# Pure integer math with round-half-up to match the old awk %.0f / %.1f. Sets REPLY.
humanize() {
  local n=$1
  if [ -z "$n" ]; then REPLY=0; return; fi
  if [ "$n" -ge 1000000 ]; then
    local t=$(( (n + 50000) / 100000 ))   # tenths of a million, rounded
    REPLY="$(( t / 10 )).$(( t % 10 ))M"
  elif [ "$n" -ge 1000 ]; then
    REPLY="$(( (n + 500) / 1000 ))k"
  else
    REPLY="$n"
  fi
}

# Format seconds into a countdown: "2h30m", "3d4h", "45m", etc. Sets REPLY.
fmt_countdown() {
  local secs=$1
  if [ "$secs" -le 0 ]; then REPLY=now; return; fi
  local days=$(( secs / 86400 )) hours=$(( (secs % 86400) / 3600 )) mins=$(( (secs % 3600) / 60 ))
  if   [ "$days"  -gt 0 ]; then REPLY="${days}d${hours}h"
  elif [ "$hours" -gt 0 ]; then REPLY="${hours}h${mins}m"
  else REPLY="${mins}m"; fi
}

# EPOCHSECONDS is a bash builtin (>= 4.2) — no date(1) fork. Undefined on stock
# macOS /bin/bash (3.2); the env-bash shebang resolves to a modern bash here.
now=$EPOCHSECONDS

# ===========================================================================
# Line 1: model | location | ctx | 5h | 7d | cost
# ===========================================================================
parts=()

# Model (bright cyan bold)
parts+=("${BOLD_CYAN}${model}${RESET}")

# Location: folder + git branch + worktree
if [ -n "$cwd" ]; then
  folder=${cwd##*/}                                   # basename, no fork
  loc_str="${BLUE}${folder}${RESET}"
  # Try branch directly; empty result = not a repo / detached with no name.
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  [ -n "$branch" ] && loc_str="${loc_str}${DIM}:${RESET}${BOLD_YELLOW}${branch}${RESET}"
  [ -n "$worktree_name" ] && loc_str="${loc_str}${DIM}[wt]${RESET}"
  parts+=("$loc_str")
fi

# Context window percentage
if [ -n "$used_disp" ]; then
  pct_color "$used_int"
  parts+=("${DIM}ctx:${RESET}${REPLY}${used_disp}%${RESET}")
fi

# Session (5h) rate limit with reset countdown
if [ -n "$five_disp" ]; then
  pct_color "$five_int"
  label="${DIM}5h:${RESET}${REPLY}${five_disp}%${RESET}"
  if [ -n "$five_resets" ]; then
    fmt_countdown "$(( five_resets - now ))"
    label="${label}${DIM}(${REPLY})${RESET}"
  fi
  parts+=("$label")
fi

# Weekly (7d) rate limit with reset countdown
if [ -n "$week_disp" ]; then
  pct_color "$week_int"
  label="${DIM}7d:${RESET}${REPLY}${week_disp}%${RESET}"
  if [ -n "$week_resets" ]; then
    fmt_countdown "$(( week_resets - now ))"
    label="${label}${DIM}(${REPLY})${RESET}"
  fi
  parts+=("$label")
fi

# Cumulative cost from API (cost_cents is integer cents, formatted in jq)
if [ -n "$cost_cents" ]; then
  d=$(( cost_cents / 100 )); c=$(( cost_cents % 100 ))
  [ "$c" -lt 10 ] && c="0$c"
  parts+=("${DIM}cost:${RESET}${BRIGHT_WHITE}\$${d}.${c}${RESET}")
fi

# ===========================================================================
# Line 2: cache | diff | r w fresh gen | agents | web | tools
# Cumulative across the session, parsed from the transcript JSONL.
# ===========================================================================
cache_part=""; tok_part=""; agents_part=""; web_part=""; tools_part=""; diff_part=""

# Code churn comes from the cost block — no transcript needed.
if [ -n "$lines_added" ] && [ -n "$lines_removed" ]; then
  if [ "$lines_added" -gt 0 ] 2>/dev/null || [ "$lines_removed" -gt 0 ] 2>/dev/null; then
    diff_part="${DIM}diff:${RESET}${GREEN}+${lines_added}${RESET} ${RED}-${lines_removed}${RESET}"
  fi
fi

# --- jq call #2: one pass over the transcript -> TSV of session stats ---
# Falls back silently (no line 2 stats) on any error or missing file.
PARSE='{
  toolnames: [ .[] | .message.content? // empty
               | if type=="array" then .[] else empty end
               | select(.type? == "tool_use") | .name ],
  in:  ([ .[].message.usage.input_tokens? // 0 ] | add),
  out: ([ .[].message.usage.output_tokens? // 0 ] | add),
  cw:  ([ .[].message.usage.cache_creation_input_tokens? // 0 ] | add),
  cr:  ([ .[].message.usage.cache_read_input_tokens? // 0 ] | add),
  ws:  ([ .[].message.usage.server_tool_use?.web_search_requests? // 0 ] | add),
  wf:  ([ .[].message.usage.server_tool_use?.web_fetch_requests? // 0 ] | add)
}
| [ (.toolnames | length),
    ([ .toolnames[] | select(. == "Task" or . == "Agent") ] | length),
    ( [ .toolnames[] | select((. == "Task" or . == "Agent") | not) ]
      | group_by(.) | map({k: .[0], n: length})
      | sort_by(-.n) | .[0:3] | map("\(.k)·\(.n)") | join(" ") ),
    .in, .out, .cw, .cr, (.ws + .wf) ]
| map(tostring) | join("")'

if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  IFS=$'\x1f' read -r t_tools t_agents t_top t_in t_out t_cw t_cr t_web \
    < <(jq -s -r "$PARSE" "$transcript" 2>/dev/null)

  if [ -n "$t_tools" ]; then
    # Cache hit rate = cache_read / (cache_read + cache_creation + fresh input)
    in_total=$(( t_cr + t_cw + t_in ))
    if [ "$in_total" -gt 0 ] 2>/dev/null; then
      hit=$(( (100 * t_cr + in_total / 2) / in_total ))   # round-half-up
      pct_color_inv "$hit"
      cache_part="${DIM}cache:${RESET}${REPLY}${hit}%${RESET}"
      humanize "$t_cr"; hr=$REPLY
      humanize "$t_cw"; hw=$REPLY
      humanize "$t_in"; hf=$REPLY
      humanize "$t_out"; hg=$REPLY
      tok_part="${DIM}r${RESET}${hr} ${DIM}w${RESET}${hw} ${DIM}fresh${RESET}${hf} ${DIM}gen${RESET}${hg}"
    fi

    [ "$t_agents" -gt 0 ] 2>/dev/null && \
      agents_part="${DIM}agents:${RESET}${MAGENTA}${t_agents}${RESET}"

    [ "$t_web" -gt 0 ] 2>/dev/null && \
      web_part="${DIM}web:${RESET}${CYAN}${t_web}${RESET}"

    if [ "$t_tools" -gt 0 ] 2>/dev/null; then
      tools_part="${DIM}tools:${RESET}${BRIGHT_WHITE}${t_tools}${RESET}"
      [ -n "$t_top" ] && tools_part="${tools_part} ${DIM}(${t_top})${RESET}"
    fi
  fi
fi

# Assemble line 2 in the requested order, skipping empties.
line2_parts=()
for p in "$cache_part" "$diff_part" "$tok_part" "$agents_part" "$web_part" "$tools_part"; do
  [ -n "$p" ] && line2_parts+=("$p")
done

# Join a list of parts with a dim pipe separator. Sets REPLY.
sep="${DIM}|${RESET}"
join_parts() {
  local r=""
  for p in "$@"; do
    if [ -z "$r" ]; then r="$p"; else r="${r}${sep}${p}"; fi
  done
  REPLY="$r"
}

join_parts "${parts[@]}"
printf '%s' "$REPLY"
if [ "${#line2_parts[@]}" -gt 0 ]; then
  join_parts "${line2_parts[@]}"
  printf '\n%s' "$REPLY"
fi
