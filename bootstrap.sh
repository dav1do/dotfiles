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
# Phases: brew files shell rust node helix plugins pueue check
# Every phase is idempotent and safe to re-run.

set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
DRY_RUN=0
NODE_MAJOR=26

# ── package lists (mirror README "Tools") ──
FORMULAE=(
  lsd ripgrep bat fd sd zoxide fzf glow tlrc jq # core
  gh lazygit direnv git-delta protobuf tuicr    # dev (tuicr = code review TUI)
  hyperfine pueue                               # benchmarks, job queue (see the pueue phase)
  cmake ninja curl                              # build deps (helix, tmux-thumbs)
  postgresql@16 libpq@16 pgvector sqldiff pspg  # databases (pspg = PSQL_PAGER in .psqlrc)
  cpm                                           # migrations (sqitch installs separately)
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

# Best-effort run, for the update phase only. `set -e` plus `run` means one
# updater failing takes the whole phase with it — a yazi plugin with local
# edits used to skip rustup, tpm and toolchain-check entirely.
try() {
  if ((DRY_RUN)); then
    printf '    [dry-run] %s\n' "$*"
  elif ! "$@"; then
    warn "failed, continuing: $*"
  fi
}

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

  # Every sqitch engine is an opt-in build option, and brew applies options to
  # every formula on the command line, so sqitch can't ride along in FORMULAE.
  # The tap ships no bottle either: each install compiles against whatever perl
  # is current and hardcodes that Cellar path in the wrapper's shebang, so a
  # perl major bump gives "bad interpreter" until it's rebuilt.
  local sqitch=(sqitchers/sqitch/sqitch --with-postgres-support --with-sqlite-support)
  if ! brew list --versions sqitch >/dev/null 2>&1; then
    info "sqitch"
    run brew install "${sqitch[@]}"
  else
    local sqitch_perl
    sqitch_perl="$(sed -n '1s|^#!\([^ ]*\).*|\1|p' "$(brew --prefix sqitch)/libexec/sqitch" 2>/dev/null)"
    if [[ -n "$sqitch_perl" && ! -x "$sqitch_perl" ]]; then
      warn "sqitch was built against $sqitch_perl, which is gone; rebuilding"
      run brew reinstall "${sqitch[@]}"
    else
      info "sqitch (present)"
    fi
  fi

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
  # --exclude .claude/: handled separately below, because settings.json must not
  # ride along.
  run rsync -a --exclude '.claude/' --exclude '.DS_Store' "$DOTFILES/home/" "$HOME/"
  info "everything except .claude/"

  # Live owns settings.json: it carries per-project permission grants and UI
  # keys (spinnerVerbs and friends) that the tracked copy omits on purpose, so a
  # plain copy would clobber the real one. Merge that file by hand. Everything
  # else under .claude/ round-trips — see CLAUDE_PATHS in sync.sh for what
  # sync.sh pulls back, and why skills/ and agents/ aren't in it.
  if [[ -d "$DOTFILES/home/.claude" ]]; then
    run rsync -a --exclude 'settings.json' --exclude '.DS_Store' \
      "$DOTFILES/home/.claude/" "$HOME/.claude/"
    info ".claude/ (except settings.json — merge that one by hand)"
  fi

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

phase_pueue() {
  say "pueue: daemon + groups"
  have pueue || {
    warn "pueue not installed — run the brew phase first"
    return 0
  }

  # launchd rather than a shell one-liner: pueued has to outlive the terminal
  # that queued the job. It's also why the config sits at pueue's own default
  # path — launchd never reads .zshenv, so PUEUE_CONFIG_PATH wouldn't reach it.
  if brew services list 2>/dev/null | grep -qE '^pueue[[:space:]]+started'; then
    info "pueued (running)"
  else
    run brew services start pueue
  fi

  if ((DRY_RUN)); then
    printf '    [dry-run] pueue group add build --parallel 1\n'
    return 0
  fi

  # The socket isn't up the instant launchd returns.
  for _ in 1 2 3 4 5; do
    pueue status >/dev/null 2>&1 && break
    sleep 1
  done
  pueue status >/dev/null 2>&1 || {
    warn "pueued not answering — check: brew services list; tail /opt/homebrew/var/log/pueued.log"
    return 0
  }

  # Groups live in the state file, not the config, so they can't be shipped in
  # pueue.yml. `add` on an existing group is an error, not a no-op.
  local out
  out="$(pueue group add build --parallel 1 2>&1)" || true
  case "$out" in
    *"already exists"*) info "group build (present)" ;;
    *) info "${out:-group build added}" ;;
  esac
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
      - ~/.claude/settings.json is the one file this script won't push. Live
        holds per-project permission grants the tracked copy omits, so merge
        home/.claude/settings.json into it by hand.
      - corepack per node version you develop on: `corepack enable`
        (not bundled from node 25 on — add it to default-packages if needed).
EOF
}

phase_update() {
  say "Updating an already-provisioned machine"
  if have brew; then
    try brew update
    try brew upgrade
    try brew upgrade --cask --greedy
    try brew cleanup
  fi
  have gh && try gh extension upgrade --all
  # Aborts if a plugin has local edits. `ya pkg upgrade --discard` is the fix,
  # but only once you've checked the diff — don't put --discard in here.
  have ya && try ya pkg upgrade
  # The daemon keeps running the old binary after an upgrade, and pueue_lib's
  # protocol version is part of the handshake — the client will tell you to
  # restart it. Do it here instead.
  if have pueue && brew services list 2>/dev/null | grep -qE '^pueue[[:space:]]+started'; then
    try brew services restart pueue
  fi
  local tpm_update="$HOME/.config/tmux/plugins/tpm/bin/update_plugins"
  [[ -x "$tpm_update" ]] && try "$tpm_update" all
  have rustup && try rustup update
  # npm globals get no `brew upgrade`; this is the trade-off for nvm's node.
  have toolchain-check && try toolchain-check -u
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
    all) PHASES+=(brew files shell rust node helix plugins pueue check) ;;
    brew | files | shell | rust | node | helix | plugins | pueue | check | update) PHASES+=("$arg") ;;
    *)
      echo "unknown argument: $arg (try --help)" >&2
      exit 2
      ;;
  esac
done
((${#PHASES[@]})) || PHASES=(brew files shell rust node helix plugins pueue check)

((DRY_RUN)) && say "DRY RUN — nothing will be changed"

for p in "${PHASES[@]}"; do
  "phase_$p"
done

say "Done: ${PHASES[*]}"
echo "    Open a new shell (or exec zsh) to pick up PATH changes."
