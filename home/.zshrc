# Anything that may prompt for console input must go above this block.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS

# $HOME/bin holds the rust-analyzer symlink (see README)
export PATH="/opt/homebrew/opt/llvm/bin":"$HOME/bin":"$HOME/.codeium/windsurf/bin":$PATH

# ignore ctrl+d
set -o ignoreeof
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

# ── Plugin selection (feature-detected; same .zshrc across machines) ────────
plugins=(rust git zsh-autosuggestions zsh-syntax-highlighting)

command -v docker >/dev/null && plugins+=(docker docker-compose)
command -v aws    >/dev/null && plugins+=(aws)
command -v gh     >/dev/null && plugins+=(gh)

# The omz gcloud plugin doesn't search ~/bin; point it at the SDK if present.
if [[ -d "$HOME/bin/google-cloud-sdk" ]]; then
  export CLOUDSDK_HOME="$HOME/bin/google-cloud-sdk"
  plugins+=(gcloud)
elif command -v gcloud >/dev/null; then
  plugins+=(gcloud)
fi

if [[ -n "$(ls $HOME/.ssh/id_* 2>/dev/null)" ]]; then
  zstyle :omz:plugins:ssh-agent quiet yes
  zstyle :omz:plugins:ssh-agent lazy yes
  zstyle :omz:plugins:ssh-agent ssh-add-args --apple-load-keychain
  plugins+=(ssh-agent)
fi

[[ -d "$HOME/.docker/completions" ]] && fpath=("$HOME/.docker/completions" $fpath)

# Skips the compinit security audit. If a new completion doesn't show up:
# rm ~/.zcompdump* && exec zsh
export ZSH_DISABLE_COMPFIX=true

source $ZSH/oh-my-zsh.sh

export EDITOR="hx"
export VISUAL="hx"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"   # avoids garbled output on some systems

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# rust
RUST_BACKTRACE=1

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# --cmd cd rather than an alias: an alias leaves zoxide's completer on `z` while
# `cd` keeps zsh's `_cd`, and doesn't apply inside already-parsed functions.
# Casualty: `cd -P/-q/-s/-L` fail. `cd -`, `cd -2`, `cd +1` are unaffected.
if command -v zoxide >/dev/null; then
  eval "$(zoxide init zsh --cmd cd)"
  # --cmd cd renames z/zi to cd/cdi; keep the old names.
  alias z='cd' zi='cdi'
fi
# {2..} skips zoxide's score column.
export _ZO_FZF_OPTS="--height 40% --reverse --preview 'lsd -a --color=always {2..}' --preview-window=right:50%"

[ -f "$HOME/.ghcup/env" ] && source "$HOME/.ghcup/env" # ghcup-env

export NVM_DIR="$HOME/.nvm"
# Lazy — sourcing nvm.sh eagerly costs ~200ms per shell. Only for `nvm` itself
# and version switching: .zshenv puts the default node on PATH statically, so
# node/prettier/language servers work in shells where these stubs never fire.
# Don't make it eager to "fix" PATH. The helper is double-underscored because
# Claude Code's shell snapshot strips single-underscore functions.
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  __nvm_lazy_load() {
    unset -f nvm node npm npx __nvm_lazy_load
    \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  }
  nvm()  { __nvm_lazy_load; nvm "$@"; }
  node() { __nvm_lazy_load; node "$@"; }
  npm()  { __nvm_lazy_load; npm "$@"; }
  npx()  { __nvm_lazy_load; npx "$@"; }
fi

[[ $commands[kubectl] ]] && source <(kubectl completion zsh)

if tty -s; then
  export GPG_TTY=$(tty)
fi

# --height stays out of DEFAULT_OPTS: a TUI that spawns fzf itself (yazi's fzf
# plugin) releases the terminal and expects fullscreen, and an inherited
# --height puts fzf in inline mode, painting over the leftover screen.
export FZF_DEFAULT_OPTS="--layout=reverse --border"
export FZF_CTRL_T_OPTS="--height 40% --preview 'bat --color=always --style=numbers {} 2>/dev/null || lsd -a --color=always {}'"
export FZF_ALT_C_OPTS="--height 40% --preview 'lsd -a --color=always {}'"
export FZF_CTRL_R_OPTS="--height 40%"
command -v fzf >/dev/null && source <(fzf --zsh)

# direnv 2.37.1 prints "loading .envrc" to stderr; swallow it. stdout (the
# eval'd exports) still flows.
if command -v direnv >/dev/null; then
  eval "$(direnv hook zsh)"
  _direnv_hook() {
    trap -- '' SIGINT
    eval "$(command direnv export zsh 2>/dev/null)"
    trap - SIGINT
  }
fi

export PATH="$HOME/.local/bin:$PATH"

y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

urlparse() {
  local mode="$1"
  shift
  local str="$*"
  case "$mode" in
    -e|--encode)
      python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))' "$str"
      ;;
    -d|--decode)
      python3 -c 'import sys, urllib.parse; print(urllib.parse.unquote(sys.argv[1]))' "$str"
      ;;
    *)
      echo "Usage: urlparse [-e|-d] string" >&2
      return 1
      ;;
  esac
}

export CLAUDE_CODE_NO_FLICKER=1 # breaks normal-mode scrollback (use c-o transcript)
export CLAUDE_CODE_DISABLE_MOUSE=1

# Per-machine overrides — paths, secrets, work-only aliases.
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
