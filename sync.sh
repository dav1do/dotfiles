#!/usr/bin/env bash
# Sync local config files into this dotfiles repo.
# Usage: ./sync.sh

set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# Copy a directory, skipping named entries (.git, .claude, and any extra args)
copy_dir() {
    local src="$1" dest="$2"
    shift 2
    local excludes=(.git .claude "$@")
    local find_args=("$src" -mindepth 1 -maxdepth 1)
    for name in "${excludes[@]}"; do
        find_args+=(-not -name "$name")
    done
    mkdir -p "$dest"
    find "${find_args[@]}" | while read -r item; do
        if [[ -d "$item" ]]; then
            copy_dir "$item" "$dest/$(basename "$item")"
        else
            cp "$item" "$dest/"
        fi
    done
}

# ── ~/.config directories (dir-name [extra excludes...]) ──
CONFIG_DIRS=(
    alacritty
    gh-dash
    ghostty
    git
    ruff
    sesh
    tuicr
    "tmux plugins"   # skip plugins — managed by tpm
    "helix runtime"  # skip runtime — symlink to built-from-source tree
    "yazi plugins"   # skip plugins — pinned in package.toml, `ya pkg install`
)

# ── ~/Library/Preferences directories (macOS-only config homes) ──
LIBRARY_DIRS=(
    glow             # glow.yml + the glamour style JSONs it points at
)

# ── ~/ dotfiles (copied to home/) ──
# Paths may contain directories; dirname is created on the way in.
HOME_FILES=(
    # pueue's config dir on macOS is ~/Library/Application Support/pueue. State,
    # logs and the socket are pointed at ~/.local/share/pueue by pueue.yml itself,
    # but this stays a single named file rather than a dir entry so that anything
    # pueue decides to write next to its config can't follow it into the repo.
    "Library/Application Support/pueue/pueue.yml"
    .bash_aliases
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
# Named individually rather than syncing the directory, because most of what
# lives there must never land here: projects/ and todos/ are session state,
# .credentials.json is a token, and settings.json is deliberately hand-curated —
# live carries per-project permission grants and UI keys the tracked copy omits,
# so a copy in either direction loses something. Edit home/.claude/settings.json
# and merge it into live by hand.
#
# This repo is public. skills/ and agents/ hold personal and work prompts
# (language-master, ukon-dev-review), not machine config — uncomment only if
# you've decided they can be published.
CLAUDE_PATHS=(
    CLAUDE.md
    statusline.sh
    hooks
    # skills
    # agents
)

echo "==> Syncing ~/.config directories..."
for entry in "${CONFIG_DIRS[@]}"; do
    set -- $entry                 # word-split: $1=dir, remainder=extra excludes
    dir="$1"; shift
    src="$HOME/.config/$dir"
    if [[ -d "$src" ]]; then
        copy_dir "$src" "$DOTFILES/home/.config/$dir" "$@"
        # dotfiles is the permanent track; any nested .git in the
        # destination is a local-only artifact that shouldn't live here.
        rm -rf "$DOTFILES/home/.config/$dir/.git"
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
        cp "$src" "$DOTFILES/home/$file"
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
        copy_dir "$src" "$dest" .DS_Store
        echo "    $entry/"
    elif [[ -f "$src" ]]; then
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
        echo "    $entry"
    else
        echo "    $entry (not found, skipping)"
    fi
done

echo "==> Syncing ~/.local/bin scripts (no symlinks)..."
mkdir -p "$DOTFILES/home/.local/bin"
find "$HOME/.local/bin" -maxdepth 1 -type f | while read -r f; do
    cp "$f" "$DOTFILES/home/.local/bin/"
    echo "    $(basename "$f")"
done

echo ""
echo "Done. Review changes with: cd $DOTFILES && git status"
