# Dotfiles

Most of these are optimized for my [keyboard layout](https://configure.zsa.io/ergodox-ez/layouts/L4wD0/latest/0). Might be nice to use nix or something instead of all these apps/configs, someday it'll be a script but I only need it every year or so.

### Tools

CLI:

- core: `brew install lsd ripgrep bat fd sd zoxide fzf glow tlrc jq`
- dev: `brew install gh lazygit direnv git-delta protobuf`
  - `git-delta` is wired in as git's pager and `interactive.diffFilter` (see `.gitconfig`) — without it, `git diff` fails.
- build-from-source deps (helix, tmux-thumbs): `brew install cmake ninja curl`
- databases (match `.psqlrc` / `.sqliterc`): `brew install postgresql@16 libpq@16 pgvector sqldiff`
  - migrations: `brew install sqitchers/sqitch/sqitch cpm` (sqitch is a Perl app; `cpm` installs its CPAN deps)
  - GCP: `brew install cloud-sql-proxy`
- yazi previewers: `brew install poppler ffmpeg sevenzip` (PDF / video / archive previews — yazi calls these implicitly, they aren't named in `yazi.toml`)
- docs: `brew install pandoc typst`
- language servers: `brew install marksman ruff vtsls vscode-langservers-extracted yaml-language-server bash-language-server`; `rust-analyzer` via rustup (below)
  - these used to come from nvim's Mason; with nvim gone they're installed standalone, and brew keeps them off nvm's node-version treadmill
  - `vscode-langservers-extracted` is one formula covering the json / html / css / eslint servers
  - `vtsls` is what `helix/languages.toml` names for ts/tsx/js — not `typescript-language-server`
  - not installed, add if you need them: `lua-language-server` (only Lua here was the nvim config), `gopls`
  - check any language with `hx --health <lang>`
- gh extensions:
  - `gh extension install dlvhdr/gh-dash` (PR/issue dashboard; bound to `prefix+h` in tmux)
  - `gh extension install dlvhdr/gh-enhance` (CI detail TUI for a PR; bound to `T` in gh-dash — see the `enhance` keybinding in `home/.config/gh-dash/config.yml`)
- editors: `brew install helix` (or build from source)
- file managers: `brew install yazi lf`
- formatters: `brew install prettier shfmt stylua taplo ruff`
- tmux + session picker: `brew install tmux sesh`
- k8s: `brew install kubectl`
- nvm: https://github.com/nvm-sh/nvm (note: lazy-loaded in `.zshrc`)
- claude code: https://docs.claude.com/en/docs/claude-code

Apps:

- terminal: `brew install --cask ghostty` (or `alacritty`)
- fonts: `brew install --cask font-meslo-lg-nerd-font font-symbols-only-nerd-font`
- git creds: `brew install --cask git-credential-manager` (cask, not a formula)
- tunnels: `brew install --cask ngrok`
- gpg: https://gpgtools.org/

Shell:

- ohmyzsh: `sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`
- p10k: `git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k`
- zsh-syntax-highlighting: `git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting`
- zsh-autosuggestions: `git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions`

tmux:

- plugin manager (tpm): https://github.com/tmux-plugins/tpm
- catppuccin theme: https://github.com/catppuccin/tmux
- plugins install with `prefix+I` after tpm is set up
- tmux-thumbs (hint-copy, `prefix+f`): Rust plugin — needs `cargo` (from the Rust toolchain below) to build on first install

Python:

Only used for scripts, so there's one global ruff config instead of per-project setup — `home/.config/ruff/pyproject.toml` → `~/.config/ruff/pyproject.toml`. Ruff does lint + format; no type checker (hover/completions come from Pylance in VS Code and windsurfpyright in Devin).

- `brew install ruff`
- the global config applies to any script, and to repos whose `pyproject.toml` has no `[tool.ruff]` section
- a repo that *does* define `[tool.ruff]` replaces the global config wholesale — ruff never merges configs
- editors: helix picks ruff up as a default language server, no config needed. VS Code and Devin need the `charliermarsh.ruff` extension (on both the MS marketplace and Open VSX) plus:

```jsonc
"[python]": {
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "charliermarsh.ruff",
  "editor.codeActionsOnSave": { "source.fixAll": "explicit", "source.organizeImports": "explicit" }
}
```

### My scripts

These live in `home/.local/bin/` and land on `PATH` via `.zshrc` (`export PATH="$HOME/.local/bin:$PATH"`). `./sync.sh` copies them back out of `~/.local/bin` into the repo.

| command                                                                | what it does                                                                                                                                                                                                                                                               |
| ---------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `cpf [-n] [-q] FILE...`                                                | Copy file contents (or stdin) to the clipboard. Bytes pass through untouched, summary goes to stderr, so it stays pipe-safe. `-n` strips the trailing newline.                                                                                                             |
| `git-cleanup-branches [--merged\|--gone\|--all] [--verify-pr] [--yes]` | Bucket local branches into merged / gone / local-only / diverged / active and prune the ones you name. Dry run by default; `--verify-pr` asks `gh` whether a "gone" branch's PR actually merged, so closed-unmerged work isn't deleted. Never touches `local-only`.        |
| `claude-control [summary\|send ID MSG]`                                | fzf command & control over Claude Code tmux panes — switch, dispatch a prompt, spawn, or broadcast. Bound to `prefix+P`; `claude-control summary` is a one-line status for the tmux bar (currently commented out in `tmux.conf`).                                          |
| `tmux-pane-picker [--query STRING]`                                    | Fuzzy-find and switch to any pane across all sessions, with a live capture-pane preview. Bound to `prefix+p`.                                                                                                                                                              |
| `tmux-send-pane <pane-id>`                                             | Move the current pane into another session as a split (fzf-pick the target; you stay put). Bound to `prefix+S`.                                                                                                                                                            |
| `tmux-yazi <pane-id>`                                                  | yazi in a popup that relays its `--cwd-file` back to the originating pane on quit, so `Q` leaves you where you browsed. Bound to `prefix+y`; invoked as `bash ~/.local/bin/tmux-yazi` since the file isn't executable. Only injects `cd` if the pane is at a shell prompt. |
| `pr-review.py <pr-number> [--no-cleanup]`                              | Check a PR out into a throwaway git worktree and review it with Claude Code. Not executable — run it as `python ~/.local/bin/pr-review.py 123`.                                                                                                                            |

Two shell functions live in `.zshrc` rather than on `PATH`, because they have to change the _current_ shell or shell out to python:

- `y [args]` — yazi that `cd`s the shell to wherever you quit (the non-tmux sibling of `tmux-yazi`).
- `urlparse -e|-d STRING` — URL-encode or decode a string.

Aliases are in `.bash_aliases`; the ones worth knowing about are the deliberate overrides of oh-my-zsh's git plugin (`gcm`, `gca`, `gl`, `gg`), which are commented in place.

Rust toolchain (for `rust-analyzer` in helix):

- `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`
- `rustup toolchain install nightly`
- `rustup component add rust-analyzer --toolchain nightly`

### setup

`sync.sh` and the setup below run in **opposite directions**, and only one of them is automated:

- `./sync.sh` pulls `~/` → repo. It's the normal path: edit the live config, then sync.
- `cp -r home/. ~/` pushes repo → `~/`. Only for a fresh machine, or to undo something.

So editing a file in this repo and then running `./sync.sh` silently discards the edit — the live copy wins. Edit `~/` and sync, or push the repo copy out first.

```sh
cp -r home/. ~/   # copies dotfiles + .config/ (the trailing `.` makes cp include hidden files)

# cp keeps the *destination's* mode when a file already exists, so re-runs can
# silently drop the exec bit. Put it back on the scripts that need it.
chmod +x ~/.local/bin/{cpf,claude-control,git-cleanup-branches,tmux-pane-picker,tmux-send-pane}

# Symlink rustup's nightly rust-analyzer into PATH (used by helix via $HOME/bin).
mkdir -p ~/bin
ln -sf ~/.rustup/toolchains/nightly-aarch64-apple-darwin/bin/rust-analyzer ~/bin/rust-analyzer
```

![modifiers](./modifiers.png)
![mission-control](./l-r-mission-control.png)
