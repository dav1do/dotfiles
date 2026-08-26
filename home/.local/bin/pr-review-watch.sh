#!/usr/bin/env bash
# Watches the PRs waiting on your review across ukon-core and ui, and spawns a
# headless Claude review for each one that has settled.
#
# The review runs as its own `claude -p` process, not a subagent: subagents do not
# get the Workflow tool, and /review-pr's adversarial fan-out needs it.
#
# Reviews post as a PENDING draft — visible only to you. Nothing reaches the
# author until you submit it in the GitHub UI.
#
# usage: pr-review-watch.sh [--watch] [--dry-run] [--notify-only] [--pr REPO#NUM]
set -uo pipefail

REPOS_DEFAULT="titan-index/ukon-core=$HOME/ukon/active/ukon-core titan-index/ui=$HOME/ukon/active/ui"
PRW_REPOS="${PRW_REPOS:-$REPOS_DEFAULT}"
PRW_QUIET_MIN="${PRW_QUIET_MIN:-30}" # PR must have been unchanged this long
PRW_5H_MAX="${PRW_5H_MAX:-70}"       # hold if 5-hour window is at or above this %
PRW_7D_MAX="${PRW_7D_MAX:-80}"       # hold if 7-day window is at or above this %
PRW_MODE="${PRW_MODE:-review-pr}"    # review-pr | code-review
PRW_PERMISSION="${PRW_PERMISSION:-acceptEdits}"
PRW_MODEL="${PRW_MODEL:-}" # empty = session default
PRW_USAGE_JSON="${PRW_USAGE_JSON:-/tmp/claude-statusline-debug.json}"
PRW_USAGE_STALE_MIN="${PRW_USAGE_STALE_MIN:-120}"
PRW_STATE="${PRW_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/pr-review-watch}"
PRW_INTERVAL="${PRW_INTERVAL:-600}" # --watch loop period, seconds
# `claude -p` writes nothing to ~/.claude/projects, so the .jsonl this keeps is the
# only record of a review. Megabytes each; the .txt verdicts stay forever.
PRW_LOG_KEEP_DAYS="${PRW_LOG_KEEP_DAYS:-14}"
# Each review is a Workflow fan-out. The usage gate only runs between ticks, so
# without a cap one quiet batch of PRs can spend the whole 5-hour window at once.
PRW_MAX_JOBS="${PRW_MAX_JOBS:-2}"
# release-please and dependabot PRs are the bulk of what lands in the review queue
# and there is nothing in them worth a fan-out.
PRW_SKIP_TITLE_RE="${PRW_SKIP_TITLE_RE:-^chore\(main\): release|^chore\(deps\): bump}"
# /review-pr hands its fan-out to a background Workflow and ends the turn. The
# default ceiling kills that workflow mid-flight and the run still exits rc0, so
# the review comes back empty; 0 waits for the workflow instead.
PRW_BG_WAIT_MS="${PRW_BG_WAIT_MS:-0}"

ONCE=1
DRY=0
NOTIFY_ONLY=0
ONLY_PR=""
while [ $# -gt 0 ]; do
  case "$1" in
    --watch) ONCE=0 ;;
    --dry-run) DRY=1 ;;
    --notify-only) NOTIFY_ONLY=1 ;;
    --pr)
      shift
      ONLY_PR="${1:-}"
      ;;
    -h | --help)
      sed -n '2,11p' "$0"
      exit 0
      ;;
    *)
      echo "unknown flag: $1" >&2
      exit 2
      ;;
  esac
  shift
done

case "$PRW_MODE" in
  review-pr | code-review) ;;
  *)
    echo "bad PRW_MODE: $PRW_MODE (want review-pr or code-review)" >&2
    exit 2
    ;;
esac

mkdir -p "$PRW_STATE"
# stderr, so log lines survive the command substitution around usage_gate.
log() { printf '%s %s\n' "$(date '+%H:%M:%S')" "$*" >&2; }
# Title and body go in as arguments. Interpolating them into the -e text lets a
# PR title close the AppleScript string and run `do shell script`.
notify() {
  osascript -e 'on run {t, m}
    display notification m with title t
  end run' "$1" "$2" >/dev/null 2>&1 || true
}
# Prints nothing and fails when the input is not a GitHub timestamp, so callers
# can skip the PR instead of treating it as infinitely old.
epoch() { date -j -u -f '%Y-%m-%dT%H:%M:%SZ' "$1" '+%s' 2>/dev/null; }

ME="$(gh api user -q .login)" || {
  echo "gh not authenticated" >&2
  exit 1
}

repo_dir() {
  local entry
  for entry in $PRW_REPOS; do
    [ "${entry%%=*}" = "$1" ] && {
      echo "${entry#*=}"
      return 0
    }
  done
  return 1
}

# Returns 0 to proceed; on hold, returns 1 and prints the reason.
usage_gate() {
  [ -r "$PRW_USAGE_JSON" ] || {
    log "usage: no $PRW_USAGE_JSON — proceeding"
    return 0
  }
  local age_min
  age_min=$((($(date +%s) - $(stat -f %m "$PRW_USAGE_JSON")) / 60))
  if [ "$age_min" -gt "$PRW_USAGE_STALE_MIN" ]; then
    log "usage: reading is ${age_min}m stale — proceeding"
    return 0
  fi
  local five week reset5 reset7
  read -r five week reset5 reset7 < <(jq -r '
    [ (.rate_limits.five_hour.used_percentage  // 0 | floor),
      (.rate_limits.seven_day.used_percentage  // 0 | floor),
      (.rate_limits.five_hour.resets_at        // 0),
      (.rate_limits.seven_day.resets_at        // 0) ] | @tsv' "$PRW_USAGE_JSON" | tr '\t' ' ')
  # A malformed file leaves these empty; proceed rather than wedge on a bad read.
  if [ -z "${five:-}" ] || [ -z "${week:-}" ]; then
    log "usage: could not parse $PRW_USAGE_JSON — proceeding"
    return 0
  fi
  # The file is only rewritten when a Claude session renders its statusline, so
  # a reading taken before the window rolled over stays "fresh" by mtime while
  # describing a window that no longer exists. Past its own reset, it is zero.
  local now
  now=$(date +%s)
  if [ "$reset5" -gt 0 ] && [ "$reset5" -le "$now" ]; then five=0; fi
  if [ "$reset7" -gt 0 ] && [ "$reset7" -le "$now" ]; then week=0; fi
  if [ "$five" -ge "$PRW_5H_MAX" ]; then
    echo "5h window at ${five}% (limit ${PRW_5H_MAX}%), resets $(date -r "$reset5" '+%H:%M')"
    return 1
  fi
  if [ "$week" -ge "$PRW_7D_MAX" ]; then
    echo "7d window at ${week}% (limit ${PRW_7D_MAX}%), resets $(date -r "$reset7" '+%a %H:%M')"
    return 1
  fi
  log "usage: 5h ${five}% / 7d ${week}% — ok"
  return 0
}

review_prompt() {
  case "$PRW_MODE" in
    review-pr) printf '/review-pr:review-pr %s' "$1" ;;
    code-review) printf '/code-review low %s' "$1" ;;
  esac
}

running_jobs() {
  local n
  n=$(jobs -pr | grep -c '.')
  echo "${n:-0}"
}

# Runs one review to completion. Returns claude's exit status.
run_review() {
  local repo=$1 dir=$2 num=$3 url=$4 slug=$5
  local stream="$PRW_STATE/$slug.jsonl" errlog="$PRW_STATE/$slug.err" verdict="$PRW_STATE/$slug.txt" rc
  cd "$dir" || return 1
  # stderr goes to its own file: interleaved into the stream it makes the whole
  # thing invalid JSON and jq gives up before reaching the result event.
  CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS="$PRW_BG_WAIT_MS" \
    claude -p "$(review_prompt "$num")" \
    --permission-mode "$PRW_PERMISSION" \
    --output-format stream-json --verbose \
    ${PRW_MODEL:+--model "$PRW_MODEL"} >"$stream" 2>"$errlog"
  rc=$?
  # The result event carries the final prose and the spend; everything else in the
  # stream is only interesting when a review goes wrong. A crash writes no result
  # event, so the .txt gets a stub — it stays a complete history either way.
  local summary
  summary=$(grep '^{' "$stream" | jq -r 'select(.type == "result")
    | "$\(.total_cost_usd // 0 | .*100 | round / 100) \(.num_turns // 0) turns \(.session_id)\n\(.result // "")"' \
    2>/dev/null)
  [ -n "$summary" ] || summary="no result event — see $stream / $errlog"
  printf '=== %s rc%s %s\n%s\n' "$(date '+%F %H:%M')" "$rc" "$repo#$num" "$summary" >>"$verdict"
  if [ "$rc" -eq 0 ]; then
    notify "Reviewed $repo#$num" "draft review ready — $url"
  else
    notify "$repo#$num" "review FAILED (rc $rc) — see $stream"
  fi
  return "$rc"
}

spawn_review() {
  local repo=$1 dir=$2 num=$3 title=$4 url=$5
  local slug marker
  slug="$(echo "$repo" | tr / _)-$num"
  marker="$PRW_STATE/$slug"

  # mkdir is the claim: atomic, so a second instance cannot spawn the same review.
  if ! mkdir "$marker" 2>/dev/null; then
    log "  #$num already handled — skip"
    return
  fi

  if [ "$DRY" = 1 ]; then
    rmdir "$marker"
    log "  DRY-RUN would run in $dir: claude -p \"$(review_prompt "$num")\" --permission-mode $PRW_PERMISSION"
    return
  fi

  if [ "$NOTIFY_ONLY" = 1 ]; then
    notify "Review waiting: $repo#$num" "$title"
    log "  notify-only: $url"
    return
  fi

  if [ "$(running_jobs)" -ge "$PRW_MAX_JOBS" ]; then
    rmdir "$marker"
    log "  #$num deferred — $PRW_MAX_JOBS review(s) already running"
    return
  fi

  log "  spawning $PRW_MODE for $repo#$num -> $PRW_STATE/$slug.jsonl"
  (run_review "$repo" "$dir" "$num" "$url" "$slug" || rmdir "$marker") &
}

scan_repo() {
  local repo=$1 dir=$2 now cutoff prs count
  now=$(date +%s)
  cutoff=$((now - PRW_QUIET_MIN * 60))

  # `review-requested:@me` matches only while the request is still outstanding —
  # GitHub clears it once you submit a review, which covers most of "first review only".
  if ! prs=$(gh pr list -R "$repo" --search "review-requested:@me" --state open \
    --json number,title,url,isDraft,reviews,commits,author 2>/dev/null); then
    log "$repo: gh query failed"
    return
  fi

  count=$(jq 'length' <<<"$prs")
  log "$repo: $count open request(s)"
  [ "$count" = 0 ] && return

  local num title url isdraft mine last_commit author isbot changed rfr r
  while IFS=$'\t' read -r num title url isdraft mine last_commit author isbot; do
    [ -z "$num" ] && continue
    if [ "$isdraft" = "true" ]; then
      log "  #$num draft — skip"
      continue
    fi
    if [ "$isbot" = "true" ]; then
      log "  #$num by $author — skip (bot)"
      continue
    fi
    if [ -n "$PRW_SKIP_TITLE_RE" ] && printf '%s' "$title" | grep -qE "$PRW_SKIP_TITLE_RE"; then
      log "  #$num title matches skip pattern — skip"
      continue
    fi
    # Closes the gap the search leaves: your own PENDING draft does not clear the request.
    if [ "$mine" != "0" ]; then
      log "  #$num already has your review — skip"
      continue
    fi

    if ! changed=$(epoch "$last_commit"); then
      log "  #$num no usable commit date — skip"
      continue
    fi
    # A PR flipped out of draft is new to you even when its commits are older.
    rfr=$(gh api "repos/$repo/issues/$num/timeline" --paginate \
      -q '[.[]|select(.event=="ready_for_review")|.created_at]|last // empty' 2>/dev/null)
    if [ -n "$rfr" ] && r=$(epoch "$rfr"); then
      [ "$r" -gt "$changed" ] && changed=$r
    fi

    if [ "$changed" -gt "$cutoff" ]; then
      log "  #$num changed $(((now - changed) / 60))m ago (<${PRW_QUIET_MIN}m) — wait"
      continue
    fi
    log "  #$num quiet for $(((now - changed) / 60))m: $title"
    spawn_review "$repo" "$dir" "$num" "$title" "$url"
  done < <(jq -r --arg me "$ME" '.[] | [
      .number, .title, .url, (.isDraft|tostring),
      ([.reviews[]? | select(.author.login == $me)] | length | tostring),
      ([.commits[]?.committedDate] | max // ""),
      (.author.login // ""), (.author.is_bot // false | tostring)
    ] | @tsv' <<<"$prs")
}

tick() {
  local hold
  if ! hold=$(usage_gate); then
    log "HOLD — $hold"
    notify "PR review watch paused" "$hold"
    return
  fi
  find "$PRW_STATE" -maxdepth 1 \( -name '*.jsonl' -o -name '*.err' \) -mtime +"$PRW_LOG_KEEP_DAYS" -delete 2>/dev/null
  local entry
  for entry in $PRW_REPOS; do
    scan_repo "${entry%%=*}" "${entry#*=}"
  done
}

# --pr is the test path: one named PR, in the foreground, no marker and no quiet
# window, so you can watch a real review happen and see the exit status.
if [ -n "$ONLY_PR" ]; then
  case "$ONLY_PR" in
    */*'#'*) ;;
    *)
      echo "--pr wants owner/repo#num, got: $ONLY_PR" >&2
      exit 2
      ;;
  esac
  repo="${ONLY_PR%%#*}"
  num="${ONLY_PR##*#}"
  dir=$(repo_dir "$repo") || {
    echo "$repo is not in PRW_REPOS" >&2
    exit 2
  }
  slug="$(echo "$repo" | tr / _)-$num"
  if [ "$DRY" = 1 ]; then
    echo "would run in $dir: claude -p \"$(review_prompt "$num")\" --permission-mode $PRW_PERMISSION"
    exit 0
  fi
  log "reviewing $repo#$num in $dir -> $PRW_STATE/$slug.jsonl"
  run_review "$repo" "$dir" "$num" "https://github.com/$repo/pull/$num" "$slug"
  rc=$?
  tail -n 40 "$PRW_STATE/$slug.txt" 2>/dev/null
  exit "$rc"
fi

if [ "$ONCE" = 1 ]; then
  tick
else
  # One watcher per machine. Without this a tmux bind and a shell both hold a
  # loop, and the markers only dedupe reviews, not the API traffic.
  lock="$PRW_STATE/.watch.lock"
  if ! mkdir "$lock" 2>/dev/null; then
    held=$(cat "$lock/pid" 2>/dev/null)
    if [ -n "$held" ] && kill -0 "$held" 2>/dev/null; then
      echo "already watching (pid $held)" >&2
      exit 1
    fi
    log "stale lock from pid ${held:-?} — taking it over"
    rm -rf "$lock"
    mkdir "$lock" || exit 1
  fi
  echo $$ >"$lock/pid"
  # Two traps, not one: a signal handler that only cleans up returns into the
  # while loop, so ^C would drop the lock and keep watching. EXIT does the removal.
  trap 'rm -rf "$lock"' EXIT
  trap 'log "stopped"; exit 130' HUP INT TERM

  log "watching every ${PRW_INTERVAL}s (mode=$PRW_MODE, quiet=${PRW_QUIET_MIN}m, max-jobs=$PRW_MAX_JOBS)"
  # backgrounded sleep + wait, so a HUP from `tmux kill-window` releases the lock
  # now instead of whenever the interval happens to run out.
  while :; do
    tick
    sleep "$PRW_INTERVAL" &
    wait $!
  done
fi
