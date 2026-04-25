# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS

# in case nvim is installed from source
export PATH="$(brew --prefix)/opt/llvm/bin":"$HOME/bin":"$HOME/bin/nvim/bin":"/Users/david/.codeium/windsurf/bin":$PATH

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
plugins=(aws history rust zsh-autosuggestions git docker docker-compose zsh-syntax-highlighting web-search ssh-agent)

# zstyle :omz:plugins:ssh-agent agent-forwarding yes
zstyle :omz:plugins:ssh-agent quiet yes 
zstyle :omz:plugins:ssh-agent lazy yes 
zstyle :omz:plugins:ssh-agent ssh-add-args --apple-load-keychain 
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
export EDITOR="nvim"
export VISUAL="nvim"
export MANPAGER='nvim +Man!'
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

# update RA for nvim to work (rustaceanvim/lsp config says don't use mason cause it's old, as is rustup version)
function update_latest_rust_analyzer() {
  # Find directories matching the rust-analyzer pattern, sort by version, and get the newest
  # .vscode or .windsurf depending on editor
  latest_version=$(find ~/.windsurf/extensions -name rust-analyzer | sort -V | tail -n 1)
  if [[ -n $latest_version ]]; then
    # only update if it's new
    if [[ -z $(ls -l ~/bin | rg $latest_version) ]]; then
      rm -f "$HOME/bin/rust-analyzer"
      ln -s $latest_version "$HOME/bin/rust-analyzer"
      fi
  fi
}
update_latest_rust_analyzer

# rust
RUST_BACKTRACE=1

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

eval "$(zoxide init zsh)"

[ -f "/Users/david/.ghcup/env" ] && source "/Users/david/.ghcup/env" # ghcup-env

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

[[ $commands[kubectl] ]] && source <(kubectl completion zsh)

if tty -s; then
  export GPG_TTY=$(tty)
fi

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

# Nix

if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi
# End Nix
# direnv
eval "$(direnv hook zsh)"
# end direnv
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/david/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/david/bin/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/david/bin/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/david/bin/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/david/bin/google-cloud-sdk/completion.zsh.inc'; fi
export PATH="$HOME/.local/bin:$PATH"

# Claude Code
export CLAUDE_CODE_NO_FLICKER=1
export CLAUDE_CODE_DISABLE_MOUSE=1
