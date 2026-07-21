# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS

# in case nvim is installed from source
export PATH="/opt/homebrew/opt/llvm/bin":"$HOME/bin":"$HOME/bin/nvim/bin":"/Users/david/.codeium/windsurf/bin":$PATH

# ignore ctrl+d
set -o ignoreeof
# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# ── Plugin selection (feature-detected; same .zshrc across machines) ────────
plugins=(rust git zsh-autosuggestions zsh-syntax-highlighting)

command -v docker >/dev/null && plugins+=(docker docker-compose)
command -v aws    >/dev/null && plugins+=(aws)
command -v gh     >/dev/null && plugins+=(gh)

# gcloud: omz plugin doesn't search ~/bin; point it at the SDK if present.
if [[ -d "$HOME/bin/google-cloud-sdk" ]]; then
  export CLOUDSDK_HOME="$HOME/bin/google-cloud-sdk"
  plugins+=(gcloud)
elif command -v gcloud >/dev/null; then
  plugins+=(gcloud)
fi

# ssh-agent only on machines with SSH keys configured.
if [[ -n "$(ls $HOME/.ssh/id_* 2>/dev/null)" ]]; then
  zstyle :omz:plugins:ssh-agent quiet yes
  zstyle :omz:plugins:ssh-agent lazy yes
  zstyle :omz:plugins:ssh-agent ssh-add-args --apple-load-keychain
  plugins+=(ssh-agent)
fi

# Docker CLI completions to fpath (only if Docker Desktop installed them).
[[ -d "$HOME/.docker/completions" ]] && fpath=("$HOME/.docker/completions" $fpath)

# Skip compinit security audit + dump-freshness check (single-user Mac).
# Run `rm ~/.zcompdump* && exec zsh` if a new completion isn't showing up.
export ZSH_DISABLE_COMPFIX=true

source $ZSH/oh-my-zsh.sh

# User configuration


# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi
export EDITOR="hx"
export VISUAL="hx"
#export MANPAGER='nvim +Man!'
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"   # avoids garbled output on some systems
# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# rust
RUST_BACKTRACE=1

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

command -v zoxide >/dev/null && eval "$(zoxide init zsh)"
# `zi` interactive picker: preview dir contents with lsd. {2..} skips zoxide's score column.
export _ZO_FZF_OPTS="--height 40% --reverse --preview 'lsd -a --color=always {2..}' --preview-window=right:50%"

[ -f "/Users/david/.ghcup/env" ] && source "/Users/david/.ghcup/env" # ghcup-env

export NVM_DIR="$HOME/.nvm"
# Lazy-load nvm — sourcing nvm.sh eagerly costs ~200ms per shell.
# First call to any of these stubs sources nvm and re-runs the command.
# Helper is double-underscored so Claude Code's shell snapshot keeps it
# (it strips single-underscore "private" functions, which breaks the stubs).
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

# Set up fzf key bindings and fuzzy completion
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
# Ctrl-T (insert path): bat preview for files, lsd for dirs. Alt-C (cd into subdir): lsd preview.
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers {} 2>/dev/null || lsd -a --color=always {}'"
export FZF_ALT_C_OPTS="--preview 'lsd -a --color=always {}'"
command -v fzf >/dev/null && source <(fzf --zsh)

# direnv — 2.37.1 still prints "loading .envrc" + "export +VAR1..." to stderr.
# Override the hook to swallow stderr; stdout (the eval'd env exports) still flows.
if command -v direnv >/dev/null; then
  eval "$(direnv hook zsh)"
  _direnv_hook() {
    trap -- '' SIGINT
    eval "$(command direnv export zsh 2>/dev/null)"
    trap - SIGINT
  }
fi

export PATH="$HOME/.local/bin:$PATH"

function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# Claude Code
export CLAUDE_CODE_NO_FLICKER=1 # this breaks normal mode scrollback (without using c-o transcript)
export CLAUDE_CODE_DISABLE_MOUSE=1

# Devin CLI
# export DEVIN_SANDBOX=true

# Per-machine overrides — paths, secrets, work-only aliases (keep out of dotfiles repo).
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

