# Daily driving — from nvim

Operational reference. Read once, keep around for the first few weeks. Pairs with `helix-migration.md` (install/config) and `gaps.md` (what's lost).

---

## Build & runtime — what actually matters

Current setup (verified):
- `/usr/local/bin/hx` → `~/mystuff/helix/target/release/hx`
- `~/.config/helix/runtime` → `~/mystuff/helix/runtime`

**You don't need `HELIX_RUNTIME`.** Helix-loader checks `~/.config/helix/runtime` automatically — the symlink is found. The env var is only needed if you don't symlink. (`helix-migration.md` says to export it; that's redundant given the symlink. Fine to leave or remove.)

Update workflow:
```
cd ~/mystuff/helix && git pull && cargo build --release
```
Symlinks pick up the new binary and runtime atomically — versions stay in lockstep, which matters because runtime queries can change between releases.

Pin to a release tag (`git checkout 25.01.1` or current) if you want stability over master.

Avoid `cargo install --path helix-term` *with* a separate symlinked runtime — they end up in different trees and you'll eventually rebuild one without the other and get version skew.

---

## The mental model

Helix is **selection-first, verb-second**. Every motion extends a selection; every operator acts on the current selection.

- Vim: `dw` = delete-word
- Helix: `wd` = select-word, then delete

Train this for a week and `dw` starts feeling backward. Until then, the moves below are the ones that bite vim muscle memory:

| nvim | helix | note |
|---|---|---|
| `dd` | `xd` | `x` selects line; repeat to extend |
| `yy` | `xy` | |
| `cw` / `dw` | `wc` / `wd` | |
| `ciw` | `miwc` | match-inner-word, then change |
| `ci(` | `mi(c` | match-inside parens |
| `ca{` | `ma{c` | match-around braces |
| `:%s/foo/bar/g` | `%s foo<ret>c bar<esc>` | whole-file → split-by-regex → change all |
| `K` (LSP hover) | `space k` (or rebound) | default `K` is `keep_selections` |
| `Ctrl-r` (redo) | `U` | |
| `qa…q` then `@a` | `Q…Q` then `q` | record/replay inverted |
| `R` (replace mode) | `r<char>` | `R` in helix = replace selection with yanked text |

Run `hx --tutor` once. ~30 minutes. Best investment in week one.

---

## The two killer workflows

**1. Multi-cursor change** (replaces `:%s/.../...`)
```
%               select whole file
s foo<ret>      split selection into a cursor at every match of `foo`
c bar<esc>      change all to `bar`
,               collapse to single cursor
```
Scope it tighter by selecting before splitting: `mip` (paragraph) or `mif` (function, with treesitter), then `s pattern<ret>` operates only inside.

**2. Select-then-act** — read keystrokes as "what am I selecting" then "what am I doing." Always. After two days the muscle flips.

---

## Tricks reference

### Case
- `~` toggle, `` ` `` lowercase, `` Alt-` `` uppercase

### Whitespace
- `_` trim leading/trailing whitespace from selection edges
- `J` join lines (collapses spaces)
- File-wide trailing-whitespace cleanup: `auto-format = true` + LSP that does it, or `:reflow`

### Format / indent
- `=` format selection via LSP (`%=` formats whole file)
- `>` / `<` indent / unindent
- `Ctrl-c` toggle line comment

### Sort
- `:sort` — sort selected lines
- `:sort -r` — reverse

### Numbers
- `Ctrl-a` / `Ctrl-x` increment / decrement number under cursor; works across multi-cursors (turns into a counter)

### Surround
- `ms<char>` add — `ms(` wraps in `()`
- `mr<old><new>` replace — `mr'"` swaps `'…'` to `"…"`
- `md<char>` delete surrounding
- `mi<char>` / `ma<char>` select inside / around

### Align
- `&` insert spaces to align all cursors to the same column. Combined with `s` to split, aligns `=` signs in a block.

### Search reuse
- `*` set search to current selection (then `n`/`N`)
- `Alt-*` whole-word version

### Selection moves
- `,` collapse all multi-cursors to primary
- `;` collapse selection to cursor
- `Alt-;` flip selection direction (cursor ↔ anchor)
- `Alt-,` remove primary cursor only (keep others)

### Tree-sitter motions (real upgrade over nvim's incremental select)
- `Alt-o` expand selection to parent node
- `Alt-i` shrink to child
- `]f` / `[f` next / prev function
- `]c` / `[c` next / prev class/type
- `]g` / `[g` next / prev diagnostic

### Goto submode (`g`)
- `gg` / `ge` top / bottom of file
- `gh` / `gl` line start / end
- `gs` first non-blank
- `gd` definition, `gr` references, `gy` type def, `gi` implementation
- `ga` last-accessed file (toggle)

### Yank without clobber
- `Alt-d` delete without yanking (vim's `"_d`)
- `Alt-c` change without yanking
- Or: `"_d` explicitly — `_` is the null register

---

## Multi-cursor primer

Three keys to learn first:

- **`C`** — add cursor on the next line at the same column. Repeat to stack. `Cwwc` = make identical changes on N consecutive lines. `Alt-c` = upward.
- **`s`** — split current selection by regex. After `%`, `s\w+<ret>` puts a cursor at every word. Or `s,<ret>` at every comma. **This is the one.**
- **`,`** — collapse to single cursor. Panic button.

Then later:
- `S` — split on newlines (cursor at each line in selection)
- `&` — align selections by inserting spaces
- `(` / `)` — rotate primary cursor (steps the active one for view-centering)
- `Alt-(` / `Alt-)` — rotate through selection history (helix's "undo selection" — useful when you accidentally collapsed)

The shift from vim multi-cursor plugins: don't "add a cursor at next match." Make a *selection covering everything*, then *split* it into cursors. Selection-first all the way down.

---

## Pickers (`space`)

| Key | Picker |
|---|---|
| `space f` | files |
| `space b` | buffers |
| `space /` | workspace grep |
| `space s` | symbols (current file) |
| `space S` | symbols (workspace) |
| `space d` / `space D` | diagnostics file / workspace |
| `space j` | jumplist |
| `space '` | resume last picker |
| `space r` | rename symbol (LSP) |
| `space a` | code actions |
| `space y` / `space p` | yank to / paste from system clipboard |
| `space k` | hover (LSP) |
| `space e` | file explorer |

Two clipboard notes: helix yanks to its own register by default. `space y`/`space p` are the explicit system-clipboard versions. If you want every yank to system clipboard, set it in config — but the explicit form keeps registers cleaner and is faster than reaching for `"+y`.

---

## Splits & navigation

`Ctrl-w` is the prefix (vim-style):
- `Ctrl-w v` / `Ctrl-w s` vertical / horizontal
- `Ctrl-w h/j/k/l` navigate
- `Ctrl-w q` close split
- `Ctrl-w o` only — close all but current

Per the comment in `tmux.conf`, vim-tmux-navigator does **not** forward `C-h/j/k/l` to helix — so use `Ctrl-w h/j/k/l` for split nav inside helix; `C-h/j/k/l` will jump panes in tmux instead. This is intentional.

`Ctrl-i` / `Ctrl-o` — forward / back in jump list.

---

## Current rebinds — audit

```toml
[keys.normal]
C-s = ":w"
S-h = ":buffer-previous"
S-l = ":buffer-next"
esc = ["collapse_selection", "keep_primary_selection"]
```

| Binding | Verdict |
|---|---|
| `C-s` save | Standard. Save without leaving insert mode is the real win. |
| `S-h`/`S-l` buffer nav | Defensible. Cost: lose default `extend_char_left/right` — but vim refugees rarely reach for that. Matches tmux/browser tab muscle memory. |
| `esc` collapse + keep-primary | **Essential.** The single most important vim-refugee rebind. Don't touch. |

```toml
[keys.select]
J = [extend_to_line_bounds, delete_selection, paste_after, move_line_down]
K = [extend_to_line_bounds, delete_selection, paste_before, move_line_up]
">" = ["indent", "collapse_selection"]
"<" = ["unindent", "collapse_selection"]
```

| Binding | Verdict |
|---|---|
| Select-mode `J`/`K` line move | Good idiom. Cost: lose `J` = `join_selections` and `K` = `keep_selections` in select mode. Worth it. |
| `>`/`<` collapse-after | Quality of life — defaults leave you with a dangling selection. Keep. |

### Recommended additions

```toml
[keys.normal]
K = "hover"

# Once Alt-key works through tmux (see below), add:
A-j = ["extend_to_line_bounds", "delete_selection", "paste_after", "move_line_down"]
A-k = ["extend_to_line_bounds", "delete_selection", "paste_before", "move_line_up"]
```

- `K = "hover"` — matches vim/nvim LSP muscle memory. Loses `keep_selections`; access via `:keep-selections <regex>` if you ever miss it (you probably won't).
- Normal-mode `A-j`/`A-k` — matches VS Code Alt-↓/↑ exactly. Without this, line-move requires `v` first to enter select mode. Keep the select-mode bindings too — they handle multi-line ranges.

### Lost from `Ctrl-s` rebind
You overrode the default `Ctrl-s = save_selection` (pushes current selection onto the selection ring for later recall via `Alt-(`). Almost no one uses this. Acceptable trade.

---

## Alt-key fix (Ghostty + tmux)

Setup is **already correct**:
- Ghostty: `macos-option-as-alt = true` ✓
- tmux: `xterm-keys on`, `extended-keys on`, `escape-time 0` ✓

Verify end-to-end: at a zsh prompt run `cat -v`, press Option-j. Expect `^[j` (escape + j). If you see `∆`, the chain is broken.

One tightening worth making in `tmux.conf` — current pattern only matches `xterm*`:
```
set -as terminal-features 'tmux*:extkeys,xterm*:extkeys'
```
This ensures CSI-u extended encoding is offered both directions (helix sees `tmux-256color` inside tmux).

---

## Editing gotchas (vim refugees)

- **`R`** — replace selection with yanked content (not enter-replace-mode). To replace each character of selection with a single char: `r<char>`.
- **`U`** — redo (not vim's revert-line).
- **`J`** — join puts cursor at the join point, not at the original position.
- **`Q`/`q`** — record / replay macros, inverted from vim.
- **`*`** — sets search register from selection. To search-and-jump like vim's `*`, follow with `n`.
- **`f<char>`** — only goes to next match; repeat with `Alt-.` (NOT `;` — that's collapse).
- **No `:s/foo/bar/`** — use the multi-cursor flow above. Or for symbol-aware rename, `space r`.
- **No marks like vim's `ma` / `'a`** — use selection registers (`"a` prefix) and the selection ring (`Alt-(` / `Alt-)`).

---

## Useful commands

- `:reload` / `:reload-all` — pick up file changes made outside helix
- `:format` — explicit format (or `=` on selection)
- `:keep-selections <regex>` — the unbound version
- `:sort` / `:sort -r`
- `:reflow` — reflow text to text-width
- `:set-language <name>` — force a language for current buffer
- `:tree-sitter-subtree` — inspect tree-sitter parse at cursor (debugging treesitter queries)
- `:config-reload` — pick up config changes without restart
- `:log-open` — view helix's log (LSP issues, etc.)
- `hx --health` — verify install and tooling per language
- `hx --health <lang>` — same, scoped
- `hx --tutor` — run again any time

---

## Discovery

- Press `g`, then wait — submode hint appears (which-key style)
- Press `m`, wait — match-mode hints
- Press `space`, wait — picker menu
- `?` after some submodes shows the full keymap

`config-reload` + a scratch keymap is the fastest way to test bindings without restarting.

---

## Suggestions worth considering

Not changes I'd make for you — just things to evaluate over the first few weeks.

1. **Soft-wrap default.** Your config has `[editor.soft-wrap] enable = true`. Unusual for code; common for prose. If you find lines wrapping in code awkwardly, flip it. If you write a lot of markdown in helix, leave it.
2. **`scrolloff = 8`** — fine, but combined with `bufferline = "multiple"` the visible code area gets tight on small terminals. If you go full-height tmux pane, no issue.
3. **`completion-trigger-len = 2`** — aggressive. Might want `3` if completion popups feel noisy.
4. **System clipboard default.** If you find `space y` annoying, set:
   ```toml
   [editor]
   default-yank-register = "+"
   ```
   Yanks go to system clipboard, internal register still accessible via `"a`–`"z`.
5. **`hx --config /tmp/test.toml file.txt`** — test config changes without modifying the live one. Useful when iterating on keymaps.
6. **Theme caveat.** `catppuccin_mocha` ships with helix; matches your tmux theme. If you build at master and it disappears, fall back to `base16_default_dark` or pin the helix tag.
7. **Workflow**: when starting a new session, prefer `space f` from the project root over `:o path` — the picker is faster than typing paths and gives you preview.

---

## When stuck

- `space ?` — typable command picker (search by name)
- `:help <command>` — built-in help
- Helix discord / matrix is active; defaults change between releases so search by version
- `git log` in `~/mystuff/helix` for a fast "what changed" before/after a `git pull` that broke something
