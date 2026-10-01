#!/usr/bin/env bash
# Sync local config files into this dotfiles repo.
# Usage: ./sync.sh

set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# Mirror a directory, skipping named entries at any depth (.git, .claude, .DS_Store,
# and any extra args). --delete: live is the source, so a file removed there goes.
copy_dir() {
  local src="$1" dest="$2"
  shift 2
  local args=(-a --delete)
  for name in .git .claude .DS_Store "$@"; do
    args+=(--exclude "$name")
  done
  mkdir -p "$dest"
  rsync "${args[@]}" "$src/" "$dest/"
}

# ── ~/.config directories (dir-name [extra excludes...]) ──
CONFIG_DIRS=(
  gh-dash
  ghostty
  git
  ruff
  sesh
  tuicr
  "tmux plugins"  # skip plugins — managed by tpm
  "helix runtime" # skip runtime — symlink to built-from-source tree
  "yazi plugins"  # skip plugins — pinned in package.toml, `ya pkg install`
)

# ── ~/Library/Preferences directories (macOS-only config homes) ──
LIBRARY_DIRS=(
  glow # glow.yml + the glamour style JSONs it points at
)

# ── ~/ dotfiles (copied to home/) ──
# Paths may contain directories; dirname is created on the way in.
HOME_FILES=(
  .bash_aliases
  .gitattributes
  .gitconfig
  .gitignore
  .p10k.zsh
  .pspg_theme_catppuccin
  .psqlrc
  .sqliterc
  .zprofile
  .zshenv
  .zshrc
)

# ── ~/.claude entries (copied to home/.claude) ──
# Named individually, not synced wholesale: projects/ and todos/ are session
# state, .credentials.json is a token, and settings.json is handled below. This
# repo is public, so skills/ and agents/ stay out unless you've decided those
# prompts can be published.
CLAUDE_PATHS=(
  CLAUDE.md
  statusline.sh
  hooks
  # skills
  # agents
)

echo "==> Syncing ~/.config directories..."
for entry in "${CONFIG_DIRS[@]}"; do
  set -- $entry # word-split: $1=dir, remainder=extra excludes
  dir="$1"
  shift
  src="$HOME/.config/$dir"
  if [[ -d "$src" ]]; then
    copy_dir "$src" "$DOTFILES/home/.config/$dir" "$@"
    echo "    $dir"
  else
    echo "    $dir (not found, skipping)"
  fi
done

echo "==> Syncing ~/Library/Preferences directories..."
for dir in "${LIBRARY_DIRS[@]}"; do
  src="$HOME/Library/Preferences/$dir"
  if [[ -d "$src" ]]; then
    copy_dir "$src" "$DOTFILES/home/Library/Preferences/$dir"
    echo "    $dir"
  else
    echo "    $dir (not found, skipping)"
  fi
done

echo "==> Syncing home files..."
for file in "${HOME_FILES[@]}"; do
  src="$HOME/$file"
  if [[ -f "$src" ]]; then
    mkdir -p "$(dirname "$DOTFILES/home/$file")"
    cp -p "$src" "$DOTFILES/home/$file"
    echo "    $file"
  else
    echo "    $file (not found, skipping)"
  fi
done

echo "==> Syncing ~/.claude..."
for entry in "${CLAUDE_PATHS[@]}"; do
  src="$HOME/.claude/$entry"
  dest="$DOTFILES/home/.claude/$entry"
  if [[ -d "$src" ]]; then
    copy_dir "$src" "$dest"
    echo "    $entry/"
  elif [[ -f "$src" ]]; then
    mkdir -p "$(dirname "$dest")"
    cp -p "$src" "$dest"
    echo "    $entry"
  else
    echo "    $entry (not found, skipping)"
  fi
done

# Live settings.json is the real one; the tracked copy is it minus spinnerVerbs,
# kept out because this repo is public. bootstrap.sh never pushes it back.
jq 'del(.spinnerVerbs)' "$HOME/.claude/settings.json" >"$DOTFILES/home/.claude/settings.json"
echo "    settings.json (minus spinnerVerbs)"

echo "==> Syncing ~/.local/bin scripts (no symlinks)..."
mkdir -p "$DOTFILES/home/.local/bin"
find "$HOME/.local/bin" -maxdepth 1 -type f | while read -r f; do
  cp -p "$f" "$DOTFILES/home/.local/bin/"
  echo "    $(basename "$f")"
done

echo ""
echo "Done. Review changes with: cd $DOTFILES && git status"
