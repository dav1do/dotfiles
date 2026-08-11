#!/usr/bin/env bash
# Push this repo out to a machine and install everything the README names.
# The opposite direction from ./sync.sh, which pulls ~/ -> repo.
#
# Usage:
#   ./bootstrap.sh                 # every phase, in order
#   ./bootstrap.sh files brew      # only the named phases
#   ./bootstrap.sh -n all          # print what would run, change nothing
#   ./bootstrap.sh update          # upgrade an already-provisioned machine
#
# Phases: brew files shell rust node helix plugins check
# Every phase is idempotent and safe to re-run.

set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
DRY_RUN=0
NODE_MAJOR=26

# ── package lists (mirror README "Tools") ──
FORMULAE=(
  lsd ripgrep bat fd sd zoxide fzf glow tlrc jq # core
  gh lazygit direnv git-delta protobuf          # dev
  cmake ninja curl                              # build deps (helix, tmux-thumbs)
  postgresql@16 libpq@16 pgvector sqldiff pspg  # databases (pspg = PSQL_PAGER in .psqlrc)
  sqitchers/sqitch/sqitch cpm                   # migrations
  cloud-sql-proxy                               # GCP
  poppler ffmpeg sevenzip                       # yazi previewers
  pandoc typst                                  # docs
  marksman ruff                                 # language servers, native
  yazi lf                                       # file managers
  shfmt stylua taplo                            # formatters (+ ruff above)
  tmux sesh                                     # tmux + session picker
  kubectl                                       # k8s
  bottom macmon                                 # system monitors (bottom's binary is btm)
)

CASKS=(
  ghostty
  font-meslo-lg-nerd-font font-symbols-only-nerd-font
  git-credential-manager
  ngrok
)

GH_EXTENSIONS=(
  dlvhdr/gh-dash
  dlvhdr/gh-enhance
)

# Node tooling lives in nvm's default-packages, never brew. See README "Node".
NODE_PACKAGES=(
  prettier
  @vtsls/language-server
  vscode-langservers-extracted
  yaml-language-server
  bash-language-server
)

# Scripts that need the exec bit after a push. cp/rsync keep the *destination's*
# mode for files that already exist, so re-runs can silently drop it.
# pr-review.py and tmux-yazi are deliberately not executable.
EXEC_SCRIPTS=(
  claude-control
  cpf
  git-cleanup-branches
  tmux-pane-picker
  tmux-read
  tmux-send-pane
  toolchain-check
)

# ── plumbing ──
say() { printf '\n==> %s\n' "$*"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '    !! %s\n' "$*" >&2; }

run() {
  if ((DRY_RUN)); then
    printf '    [dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

# Same as run(), for things that need a shell (redirects, heredocs, pipes).
run_sh() {
  if ((DRY_RUN)); then
    printf '    [dry-run] %s\n' "$1"
  else
    bash -c "$1"
  fi
}

have() { command -v "$1" >/dev/null 2>&1; }

# ── phases ──

phase_brew() {
  say "Homebrew"
  if ! have brew; then
    run_sh '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    for p in /opt/homebrew/bin/brew /usr/local/bin/brew; do
      [[ -x "$p" ]] && eval "$("$p" shellenv)" && break
    done
  fi
  have brew || {
    warn "brew still not on PATH; skipping brew phase"
    return 0
  }

  run brew update

  info "formulae (${#FORMULAE[@]})"
  run brew install "${FORMULAE[@]}"

  info "casks (${#CASKS[@]})"
  run brew install --cask "${CASKS[@]}"

  # These break helix silently when they come from brew instead of nvm — the
  # brew build of node links 22 brew dylibs and dies on any major bump.
  local strays
  strays="$(brew list --formula 2>/dev/null \
    | grep -xE 'node|prettier|vtsls|yaml-language-server|bash-language-server|vscode-langservers-extracted' || true)"
  if [[ -n "$strays" ]]; then
    warn "brew has node-based tooling installed: $(tr '\n' ' ' <<<"$strays")"
    warn "remove it: brew uninstall $(tr '\n' ' ' <<<"$strays")"
  fi

  if have gh && gh auth status >/dev/null 2>&1; then
    info "gh extensions"
    # Captured, not piped: `... | grep -q` under pipefail reports failure when
    # grep's early exit SIGPIPEs gh, which reads as "extension not installed".
    local installed
    installed="$(gh extension list 2>/dev/null || true)"
    for ext in "${GH_EXTENSIONS[@]}"; do
      if [[ "$installed" == *"$ext"* ]]; then
        info "${ext} (present)"
      else
        run gh extension install "$ext"
      fi
    done
  else
    warn "gh not authenticated — run 'gh auth login', then: ./bootstrap.sh brew"
  fi
}

phase_files() {
  say "Pushing repo -> ~/"
  # --exclude .claude/: live owns it. The tracked settings.json is a sanitized
  # subset (spinnerVerbs and friends only exist live), so a plain copy would
  # clobber the real one. sync.sh excludes it in the pull direction too.
  run rsync -a --exclude '.claude/' --exclude '.DS_Store' "$DOTFILES/home/" "$HOME/"
  info "everything except .claude/"

  local missing=()
  for s in "${EXEC_SCRIPTS[@]}"; do
    if [[ -f "$HOME/.local/bin/$s" ]]; then
      run chmod +x "$HOME/.local/bin/$s"
    else
      missing+=("$s")
    fi
  done
  info "chmod +x on ${#EXEC_SCRIPTS[@]} scripts in ~/.local/bin"
  ((${#missing[@]})) && warn "not found: ${missing[*]}"

  # oh-my-zsh's installer wants this to exist before .zshrc sources plugins.
  run mkdir -p "$HOME/.config/tmux/plugins" "$HOME/bin"
}

phase_shell() {
  say "zsh: oh-my-zsh, p10k, plugins"
  local custom="$HOME/.oh-my-zsh/custom"

  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    info "oh-my-zsh (present)"
  else
    # KEEP_ZSHRC: the .zshrc from this repo is the real one, don't replace it.
    run_sh 'RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
  fi

  clone_once() {
    local url="$1" dest="$2" depth="${3:-}"
    if [[ -d "$dest" ]]; then
      info "$(basename "$dest") (present)"
    elif [[ -n "$depth" ]]; then
      run git clone --depth=1 "$url" "$dest"
    else
      run git clone "$url" "$dest"
    fi
  }

  clone_once https://github.com/romkatv/powerlevel10k.git "$custom/themes/powerlevel10k" 1
  clone_once https://github.com/zsh-users/zsh-syntax-highlighting "$custom/plugins/zsh-syntax-highlighting"
  clone_once https://github.com/zsh-users/zsh-autosuggestions "$custom/plugins/zsh-autosuggestions"

  say "tmux: tpm"
  clone_once https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm" 1
}

phase_rust() {
  say "Rust toolchain (builds helix, provides rust-analyzer)"
  if have rustup; then
    info "rustup (present)"
  else
    run_sh "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
    # shellcheck disable=SC1090
    [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
  fi
  have rustup || {
    warn "rustup not on PATH; skipping rust phase"
    return 0
  }

  run rustup toolchain install nightly
  run rustup component add rust-analyzer --toolchain nightly

  # helix finds rust-analyzer through ~/bin, not the rustup shim.
  local ra
  ra="$(echo "$HOME"/.rustup/toolchains/nightly-*/bin/rust-analyzer | cut -d' ' -f1)"
  if [[ -x "$ra" ]]; then
    run mkdir -p "$HOME/bin"
    run ln -sf "$ra" "$HOME/bin/rust-analyzer"
    info "~/bin/rust-analyzer -> $ra"
  else
    warn "no nightly rust-analyzer found to symlink"
  fi
}

phase_node() {
  say "node via nvm (the only node source)"
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    info "nvm (present)"
  else
    # https://raw.githubusercontent.com/nvm-sh/nvm/refs/heads/master/install.sh
    run_sh 'curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash'
  fi
  [[ -s "$NVM_DIR/nvm.sh" ]] || {
    warn "nvm not installed; skipping node phase"
    return 0
  }

  # default-packages must exist *before* nvm install — it only applies on a
  # fresh install, and nvm 0.40.2's already-installed branch has the guard
  # inverted (nvm.sh:3549 vs :3653), so it never fires there.
  run mkdir -p "$NVM_DIR"
  run_sh "printf '%s\n' $(printf '%q ' "${NODE_PACKAGES[@]}") > '$NVM_DIR/default-packages'"
  info "default-packages: ${NODE_PACKAGES[*]}"

  if ((DRY_RUN)); then
    printf '    [dry-run] nvm install %s && nvm alias default <concrete version>\n' "$NODE_MAJOR"
    return 0
  fi

  set +u
  # shellcheck disable=SC1091
  source "$NVM_DIR/nvm.sh"
  nvm install "$NODE_MAJOR"
  local concrete
  concrete="$(nvm version "$NODE_MAJOR")"
  # A concrete version, not the floating `node` alias: .zshenv reads this file
  # and needs a real directory name under ~/.nvm/versions/node.
  nvm alias default "$concrete"
  nvm use default
  # Belt and braces if $NODE_MAJOR was already installed (see the guard bug).
  nvm reinstall-packages "$concrete" 2>/dev/null || npm i -g "${NODE_PACKAGES[@]}"
  set -u
  info "default node: $concrete"
}

phase_helix() {
  # `brew install helix` is the same version and handles its own runtime, which
  # would make both symlinks below unnecessary. The source build is a choice.
  say "helix (built from source)"
  local src="$HOME/mystuff/helix"
  if [[ -d "$src/.git" ]]; then
    info "checkout present at $src"
  else
    run git clone https://github.com/helix-editor/helix "$src"
  fi

  if have cargo; then
    run_sh "cd '$src' && cargo build --release"
  else
    warn "no cargo — run the rust phase first, then: ./bootstrap.sh helix"
    return 0
  fi

  run sudo ln -sf "$src/target/release/hx" /usr/local/bin/hx
  # Not optional: a source build with no runtime tree has no highlighting,
  # no themes and no queries. sync.sh skips this path for the same reason.
  run mkdir -p "$HOME/.config/helix"
  run ln -sfn "$src/runtime" "$HOME/.config/helix/runtime"
  info "hx -> /usr/local/bin, runtime -> ~/.config/helix/runtime"
}

phase_plugins() {
  say "tmux + yazi plugins"
  local tpm="$HOME/.config/tmux/plugins/tpm/bin/install_plugins"
  if [[ -x "$tpm" ]]; then
    run "$tpm" # equivalent to prefix+I
  else
    warn "tpm not installed — run the shell phase, or press prefix+I in tmux"
  fi

  if have ya; then
    run ya pkg install
  else
    warn "yazi not installed yet; re-run after the brew phase"
  fi
}

phase_check() {
  say "Verifying"
  if have toolchain-check; then
    run toolchain-check
  else
    warn "toolchain-check not on PATH — open a new shell (PATH comes from .zshrc) and re-run"
  fi
  cat <<'EOF'

    Left to do by hand (not scriptable):
      - GPG: install GPG Suite from https://gpgtools.org/, import your key,
        then check `git config --get user.signingkey` resolves.
      - claude code: https://docs.claude.com/en/docs/claude-code
      - ~/.claude/ is not pushed by this script. Copy the bits you want from
        home/.claude/ by hand; live is the source of truth there.
      - corepack per node version you develop on: `corepack enable`
        (not bundled from node 25 on — add it to default-packages if needed).
EOF
}

phase_update() {
  say "Updating an already-provisioned machine"
  if have brew; then
    run brew update
    run brew upgrade
    run brew upgrade --cask --greedy
    run brew cleanup
  fi
  have gh && run gh extension upgrade --all
  have ya && run ya pkg upgrade
  local tpm_update="$HOME/.config/tmux/plugins/tpm/bin/update_plugins"
  [[ -x "$tpm_update" ]] && run "$tpm_update" all
  have rustup && run rustup update
  # npm globals get no `brew upgrade`; this is the trade-off for nvm's node.
  have toolchain-check && run toolchain-check -u
}

# ── arg parsing ──
PHASES=()
for arg in "$@"; do
  case "$arg" in
    -n | --dry-run) DRY_RUN=1 ;;
    -h | --help)
      sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    all) PHASES+=(brew files shell rust node helix plugins check) ;;
    brew | files | shell | rust | node | helix | plugins | check | update) PHASES+=("$arg") ;;
    *)
      echo "unknown argument: $arg (try --help)" >&2
      exit 2
      ;;
  esac
done
((${#PHASES[@]})) || PHASES=(brew files shell rust node helix plugins check)

((DRY_RUN)) && say "DRY RUN — nothing will be changed"

for p in "${PHASES[@]}"; do
  "phase_$p"
done

say "Done: ${PHASES[*]}"
echo "    Open a new shell (or exec zsh) to pick up PATH changes."
