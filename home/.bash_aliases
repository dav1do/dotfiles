alias vim='nvim'

alias ls='lsd'
alias ll='ls -al'
alias la='ls -A'
alias l='ls -CF'

alias locate='mdfind' # spotlight on mac

alias lhr='lefthook run'

alias wsl_ssh_ip='arp -a | rg "2c:f0:5d:f0:42:ed"'
# alias vi='nvim'
# alias vim='nvim'

# after upgrading alacritty, if it won't open, run: 
alias alacritty_auth='xattr -rd com.apple.quarantine /Applications/Alacritty.app'
alias install_nvim_nightly='make MAKE_BUILD_TYPE=RelWithDebInfo && make CMAKE_INSTALL_PREFIX=$HOME/bin/nvim install'

# git, you git
git_current_branch() {
  local ref
  ref=$(__git_prompt_git symbolic-ref --quiet HEAD 2>/dev/null)
  local ret=$?
  if [[ $ret != 0 ]]; then
    [[ $ret == 128 ]] && return
    ref=$(__git_prompt_git rev-parse --short HEAD 2>/dev/null) || return
  fi
  echo ${ref#refs/heads/}
}

alias unwip='git reset HEAD~1'
alias ga='git add .'
alias gs='git status'
alias gch='git checkout'
alias gcm='git commit -m'
alias gca='git commit --amend --no-edit'
alias gl='git log --graph --pretty=format:'\''%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'\'' --abbrev-commit'
alias gpsup='git push --set-upstream origin $(git_current_branch)'

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

