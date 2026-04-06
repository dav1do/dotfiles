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

# ── ~/.config directories ──
CONFIG_DIRS=(
    alacritty
    git
    nvim
    sesh
)

# ── ~/ dotfiles (copied to home/) ──
HOME_FILES=(
    .bash_aliases
    .gitconfig
    .gitignore
    .p10k.zsh
    .tmux.conf
    .zprofile
    .zshenv
    .zshrc
)

echo "==> Syncing ~/.config directories..."
for dir in "${CONFIG_DIRS[@]}"; do
    src="$HOME/.config/$dir"
    if [[ -d "$src" ]]; then
        copy_dir "$src" "$DOTFILES/home/.config/$dir"
        echo "    $dir"
    else
        echo "    $dir (not found, skipping)"
    fi
done

# tmux: skip plugins (managed by tpm)
if [[ -d "$HOME/.config/tmux" ]]; then
    copy_dir "$HOME/.config/tmux" "$DOTFILES/home/.config/tmux" plugins
    echo "    tmux"
fi

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

echo "==> Syncing ~/.local/bin scripts (no symlinks)..."
mkdir -p "$DOTFILES/home/.local/bin"
find "$HOME/.local/bin" -maxdepth 1 -type f | while read -r f; do
    cp "$f" "$DOTFILES/home/.local/bin/"
    echo "    $(basename "$f")"
done

echo ""
echo "Done. Review changes with: cd $DOTFILES && git status"
