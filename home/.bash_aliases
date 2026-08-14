alias vim='hx'

# history shortcuts (formerly from omz `history` plugin)
alias h='history'
alias hl='history | less'
alias hs='history | grep'
alias hsi='history | grep -i'

alias ls='lsd'
alias ll='ls -al'
alias la='ls -A'
alias l='ls -CF'

alias lg='lazygit'
alias ws='windsurf'

# code review TUI. `crw` reviews the working tree and skips the commit selector.
alias cr='tuicr'
alias crw='tuicr -w'

# 3 warmup runs before timing — cold caches make the first run a lie.
alias bench='hyperfine --warmup 3'

alias locate='mdfind' # spotlight on mac

alias lhr='lefthook run'

# Find the WSL box's IP by its MAC. Set WSL_MAC in ~/.zshrc.local (gitignored,
# never synced) — the MAC is a hardware identifier, so it stays out of this repo.
alias wsl_ssh_ip='arp -a | rg "${WSL_MAC:?set WSL_MAC in ~/.zshrc.local}"'

# additions (omz has no bare `gs`/`unwip`)
alias gs='git status'
alias unwip='git reset HEAD~1' # omz's gunwip is safer (only resets if HEAD is a --wip--)

# overrides (omz uses these names for other things — keep mine)
# alias ga='git add .'                     # omz: git add
alias gcm='git commit -m'                # omz: git checkout main  ⚠️
alias gca='git commit --amend --no-edit' # omz: git commit -v -a
alias gl='git log --graph --pretty=format:'\''%Cred%h%Creset %C(magenta)%G?%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'\'' --abbrev-commit'
alias gg='git pull' # gl in zsh git plugin (git get mnemonic)
alias tf='terraform'

alias k='kubectl'
complete -o default -F __start_kubectl k
# alias kubectl="minikube kubectl --"

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"

  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
fi
