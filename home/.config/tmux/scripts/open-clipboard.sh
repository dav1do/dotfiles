#!/usr/bin/env bash
# Open whatever `prefix Space` (tmux-thumbs) last copied. Bound to `prefix O`.
#
# Not just `open "$(pbpaste)"`: EDITOR is hx, a TUI that LaunchServices can't
# launch, so files need a tmux window rather than Finder; thumbs copies relative
# paths and a run-shell job starts in the server's cwd; and thumbs' url pattern
# matches scp-style git remotes, which `open` can't take.
#
# Usage: open-clipboard.sh <pane-current-path>
set -uo pipefail

pane_path="${1:-$HOME}"

# Echoes "<verdict> <target>": url, dir, file, or error (target = the message).
classify() {
  local target=$1 pane=$2 host repo rest

  [[ -n $target ]] || { echo "error clipboard is empty"; return; }

  case $target in
    # git remote spellings -> a browsable https URL. Bare ssh:// is left alone:
    # Terminal.app claims that scheme, which is at least a defensible open.
    ssh://git@* | git://*)
      rest=${target#*://}
      rest=${rest#*@}
      echo "url https://${rest%.git}"
      return
      ;;
    *://* | mailto:*)
      echo "url $target"
      return
      ;;
    # git@github.com:owner/repo.git -> https://github.com/owner/repo
    git@*:*)
      host=${target#git@}
      repo=${target#*:}
      echo "url https://${host%%:*}/${repo%.git}"
      return
      ;;
  esac

  # thumbs keeps `~` in its path pattern, and no shell expands a tilde that
  # arrived inside a variable — so it has to happen here.
  case $target in
    '~') target=$HOME ;;
    '~/'*) target="$HOME/${target#'~/'}" ;;
  esac

  # Relative paths come from thumbs far more often than absolute ones.
  [[ -e $target ]] || [[ ! -e "$pane/$target" ]] || target="$pane/$target"

  if [[ -d $target ]]; then
    echo "dir $target"
  elif [[ -e $target ]]; then
    echo "file $target"
  elif [[ $target =~ ^[A-Za-z0-9][A-Za-z0-9.-]*\.[A-Za-z]{2,}(/.*)?$ ]]; then
    # Bare host: github.com/owner/repo, www.foo.dev. Checked after the path
    # tests so a real file named notes.txt wins over https://notes.txt.
    echo "url https://$target"
  else
    echo "error can't open: $target"
  fi
}

read -r verdict target <<<"$(classify "$(pbpaste | tr -d '\r' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" "$pane_path")"

case $verdict in
  url | dir)
    if err=$(open "$target" 2>&1); then
      tmux display-message "opened $target"
    else
      tmux display-message "open: ${err:-failed} ($target)"
    fi
    ;;
  file)
    tmux new-window -c "$pane_path" "$(printf '%s %q' "${EDITOR:-hx}" "$target")"
    ;;
  *)
    tmux display-message "$target"
    ;;
esac
