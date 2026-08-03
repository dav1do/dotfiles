# Helix — daily driving reference

Operational reference for my helix setup. Keybindings below are verified against the helix
revision I actually run (`hx --version`, currently 25.07.1 / `079a789e`) by reading
`helix-term/src/keymap/default.rs` in `~/mystuff/helix` — not from memory or blog posts.
Defaults move between releases, so re-check that file after a `git pull` if something feels off.

Install and language-server setup live in the dotfiles `README.md` (helix + Python sections).

---

## Build & runtime

```
/usr/local/bin/hx          → ~/mystuff/helix/target/release/hx
~/.config/helix/runtime    → ~/mystuff/helix/runtime
```

**You don't need `HELIX_RUNTIME`.** helix-loader checks `~/.config/helix/runtime` automatically, so
the symlink is enough.

**The runtime symlink is not optional.** A source build with no runtime tree has no syntax
highlighting, no themes, and no tree-sitter queries.

Update:

```sh
cd ~/mystuff/helix && git pull && cargo build --release
```

Both symlinks pick up the new binary and runtime together, which matters because runtime queries
change between releases. Pin a tag (`git checkout 25.07.1`) if you want stability over master.

Avoid `cargo install --path helix-term` alongside a separately symlinked runtime — they land in
different trees and you'll eventually rebuild one without the other and get version skew.

brew is currently at the same version and manages its own runtime, so `brew install helix` would
make both symlinks unnecessary. The from-source setup is a choice, not a requirement.

---

## The mental model

Helix is **selection-first, verb-second**. Every motion extends a selection; every operator acts on
the current selection.

- Vim: `dw` = delete-word
- Helix: `wd` = select-word, then delete

| vim | helix | note |
|---|---|---|
| `dd` | `xd` | `x` selects line; repeat to extend |
| `yy` | `xy` | |
| `cw` / `dw` | `wc` / `wd` | |
| `ciw` | `miwc` | match-inner-word, then change |
| `ci(` | `mi(c` | match-inside parens |
| `ca{` | `ma{c` | match-around braces |
| `:%s/foo/bar/g` | `%s foo<ret>c bar<esc>` | whole-file → split-by-regex → change all |
| `Ctrl-r` (redo) | `U` | |
| `qa…q` then `@a` | `Q…Q` then `q` | record/replay inverted |
| `R` (replace mode) | `r<char>` | `R` in helix = replace selection with yanked text |

`hx --tutor` — ~30 minutes, best investment in week one.

---

## Capable → fast

Everything below in this doc is reference. These six are the actual gap between knowing helix and
being quick in it, roughly in order of payoff.

**1. `gw` — jump labels.** Type `gw`, every visible word gets a 1–2 char label, type the label, the
cursor is there. This replaces almost all `hjkl`, `w`/`b` mashing, counted motions, and `/search<ret>`
navigation-by-search. Same thing in select mode extends the selection to the label instead. It is the
single largest speed difference available and it needs no config. Drill it for a week until reaching
for `/` to move the cursor feels wrong.

`jump-label-alphabet` in `config.toml` reorders the labels into typing order (`asdfghjkl…`) so the
first ones handed out are under your fingers.

**2. `gn` / `gp` — buffer next / previous.** These are defaults. The `S-h` / `S-l` rebind commented
out in `config.toml` was solving a problem helix already solved.

**3. `ga` — last accessed file.** Alt-tab between two buffers. `gm` is last *modified* file, `g.` is
last modification *position*. Between `ga` and `gn`/`gp` you rarely need `space b`.

**4. Shell integration.** Zero bindings needed, all defaults, and the doc used to omit it entirely:

| Key | Does |
|---|---|
| `\|` | pipe selections through a command, **replace** with output |
| `A-\|` | pipe into a command, discard output |
| `!` | insert command output **before** selections |
| `A-!` | append command output **after** selections |
| `$` | keep only the selections for which the command exits 0 |

`%|jq .<ret>` reformats a JSON buffer. `!date<ret>` stamps a date. With multi-cursors each selection
is piped separately, so `s^<ret>` then `!` prefixes every line with command output. `$` is the
sleeper: split a buffer into selections, then filter them by an arbitrary predicate.

**5. Tree-sitter siblings, not just parents.** The doc had `A-o` / `A-i` only. The rest:

- `A-n` / `A-p` (also `A-right` / `A-left`) next / prev **sibling** — step through arguments, array
  elements, match arms without touching a character motion
- `A-a` select **all siblings** — instant multi-cursor over every argument or field
- `A-I` select all **children**
- `A-e` / `A-b` move to parent node **end** / **start** (extend versions in select mode)

`A-a` then `c` changes every sibling at once. That's the fastest path to "rename all these fields".

**6. Registers and macros, actually used.** `"` selects a register for the next operation, so `"ay`
yanks to `a` and `"ap` pastes it. `Q` records into the last-used register, `q` replays. Helix has no
vim marks — `space m` (rebound to `save_selection`) pushes the current selection to the jumplist and
`C-o` / `space j` come back. That's the mark story.

Two smaller ones worth internalising: `A-.` repeats the last `f`/`t` motion (not `;`), and `A-minus`
merges all selections into one span while `A-_` merges only the consecutive ones.

**What you can't do:** user configs cannot declare sticky submodes. `is_sticky` is
`#[serde(skip)]` on `KeyTrieNode`, so `Z` and `space G` being sticky is hardcoded and a `[keys.…]`
table can't reproduce it. Don't spend an evening on it.

---

## The two killer workflows

**1. Multi-cursor change** (replaces `:%s/.../...`)

```
%               select whole file
s foo<ret>      split selection into a cursor at every match of `foo`
c bar<esc>      change all to `bar`
,               collapse to single cursor
```

Scope it tighter by selecting first: `mip` (paragraph) or `mif` (function, tree-sitter), then
`s pattern<ret>` only operates inside that.

**2. Select-then-act** — read keystrokes as "what am I selecting", then "what am I doing."

---

## Tricks reference

### Case
- `~` toggle, `` ` `` lowercase, `` Alt-` `` uppercase

### Whitespace
- `_` trim leading/trailing whitespace from selection edges
- `J` join lines (collapses spaces)
- `:reflow` reflow to `text-width`

### Toggles (`space t`)
`:toggle <key>` flips any boolean `[editor]` key at runtime; with extra args it cycles string
values (`:toggle line-number relative absolute`). It's **global, not per-buffer** — helix has no
per-buffer wrap setting.

- `space t w` soft wrap · `space t W` wrap at `text-width` instead of viewport width
- `space t n` absolute ↔ relative line numbers
- `space t i` inlay hints · `space t g` indent guides

One catch: `:toggle` reads the serialized config and refuses `null`. `soft-wrap.enable` is
`Option<bool>` (shared with per-language config), so it must be set explicitly in `config.toml` —
which it is — or the toggle errors with "cannot be toggled".

### Format / indent / comment
- `=` and `space =` are both **rebound to `:format`** here. That runs the `formatter` from
  `languages.toml` (prettier, ruff, shfmt…), falling back to the LSP if the binary isn't on `PATH`
  — the same path as format-on-save, so the result never fights the next save.
- What `=` does by default, and why it's gone: `format_selections`
  (`helix-term/src/commands.rs:5238`) only asks a language server advertising
  `documentRangeFormattingProvider`. It ignores `formatter` entirely. Probing the servers this
  config actually uses:

  | language | server | range formatting | default `=` |
  |---|---|---|---|
  | python | ruff | yes | correct — ruff LSP matches `ruff format` |
  | typescript / tsx / javascript / jsx | vtsls | yes | **wrong** — reformats to tsserver style, next save reverts it to prettier's |
  | rust | rust-analyzer | no | errors |
  | json | vscode-json-language-server | no (and `format` is in `except-features`) | errors |
  | markdown, lua, bash, toml | none with format | — | errors |

  One language out of eleven. Not worth keeping a key that silently disagrees with save.
- `>` / `<` indent / unindent
- `:reflow [width]` hard-wraps the selected lines (defaults to `text-width`, 100). Prose only.
- `Ctrl-c` toggle line comment — also `space c`; `space C` block comment

### Sort
- `:sort`, `:sort -r`

### Numbers
- `Ctrl-a` / `Ctrl-x` increment / decrement the number under the cursor. Across multi-cursors this
  becomes a counter — select a column of zeros, split, then `Ctrl-a` repeatedly.

### Surround
- `ms<char>` add — `ms(` wraps in `()`
- `mr<old><new>` replace — `mr'"` swaps `'…'` for `"…"`
- `md<char>` delete surrounding
- `mi<char>` / `ma<char>` select inside / around

### Align
- `&` insert spaces to align all cursors to the same column. With `s` to split first, this aligns
  `=` signs across a block.

### Search reuse
- `*` set the search register from the selection, then `n` / `N`
- `Alt-*` whole-word version

### Selection moves
- `Alt-minus` merge all selections into one span — `Alt-_` merge only consecutive ones
- `,` collapse all multi-cursors to primary — the panic button
- `;` collapse selection to cursor
- `Alt-;` flip selection direction (cursor ↔ anchor)
- `Alt-,` remove the primary cursor, keep the rest
- `(` / `)` rotate *which* selection is primary
- `Alt-(` / `Alt-)` rotate the *contents* between selections — this shuffles your text, it is not
  an undo. Easy to fire by accident when reaching for `(` / `)`.

### Tree-sitter motions
- `Alt-o` / `Alt-i` expand to parent node / shrink to child (also `Alt-up` / `Alt-down`)
- `Alt-n` / `Alt-p` next / prev sibling (also `Alt-right` / `Alt-left`)
- `Alt-a` select all siblings — `Alt-I` select all children
- `Alt-e` / `Alt-b` move to parent node end / start
- `]f` / `[f` next / prev **function**
- `]t` / `[t` next / prev **class or type**
- `]a` / `[a` next / prev **parameter**
- `]c` / `[c` next / prev **comment**
- `]e` / `[e` next / prev entry
- `]T` / `[T` next / prev test
- `]p` / `[p` next / prev paragraph
- `]x` / `[x` next / prev XML element
- `]space` / `[space` add a blank line below / above

Two of these bite if you came in expecting vim-ish semantics: **`]c` is comment, not class**
(class is `]t`), and **`]g` is the next git change, not the next diagnostic**.

### Diagnostics vs git changes
- `]d` / `[d` next / prev diagnostic — `]D` / `[D` jump to last
- `]g` / `[g` next / prev git change — `]G` / `[G` jump to last
- `space d` / `space D` diagnostics picker, file / workspace
- `space g` picker over git-changed files

### Yank without clobber
- `Alt-d` delete without yanking (vim's `"_d`)
- `Alt-c` change without yanking
- Or `"_d` explicitly — `_` is the null register

---

## Multi-cursor primer

Three keys first:

- **`C`** — add a cursor on the next line at the same column; repeat to stack. `Cwwc` makes
  identical changes on N consecutive lines. `Alt-C` goes upward.
- **`s`** — split the current selection by regex. After `%`, `s\w+<ret>` puts a cursor at every
  word; `s,<ret>` at every comma. **This is the one that matters.**
- **`,`** — collapse to a single cursor.

Then:

- `S` split on newlines (a cursor per line in the selection)
- `&` align selections by inserting spaces
- `(` / `)` rotate the primary cursor

The shift away from vim multi-cursor plugins: don't "add a cursor at the next match." Make a
selection covering everything, then *split* it. Selection-first all the way down.

---

## Pickers (`space`)

| Key | Picker |
|---|---|
| `space f` / `space F` | files (workspace / current dir) |
| `space e` / `space .` | file explorer (workspace / buffer's dir) |
| `space b` | buffers |
| `space g` | git-changed files |
| `space /` | workspace grep |
| `space s` / `space S` | symbols (file / workspace) |
| `space d` / `space D` | diagnostics (file / workspace) |
| `space j` | jumplist |
| `space '` | resume last picker |
| `space r` | rename symbol (LSP) |
| `space a` | code actions |
| `space k` | hover — also rebound to bare `K` below |
| `space h` | select all references to the symbol under the cursor |
| `space y` / `space Y` | yank selections / main selection to system clipboard |
| `space p` / `space P` | paste from clipboard after / before |
| `space R` | replace selections with clipboard contents |
| `space c` / `space C` | toggle line / block comment |
| `space w` | window (split) submenu — same actions as `Ctrl-w` |
| `space ?` | command palette — searchable list of every command |
| `space m` | **rebound** — `save_selection`, i.e. push a jumplist mark |
| `space q` / `space Q` | **rebound** — `:buffer-close` / `:buffer-close-others` |
| `space l` / `space L` | **rebound** — `:lsp-restart` / `:log-open` |

Helix yanks to its own register by default; the `space y`/`space p` family is the explicit
system-clipboard path. Keeps registers cleaner than making `+` the default.

---

## Buffers, splits, jumps

Buffers (all defaults — no rebinds needed):

- `gn` / `gp` next / previous buffer
- `ga` last **accessed** file, `gm` last **modified** file
- `space q` closes the current buffer (rebound), `space b` picks one

`Ctrl-w` is the prefix for splits (`space w` does the same):

- `Ctrl-w v` / `Ctrl-w s` vertical / horizontal split
- `Ctrl-w h/j/k/l` navigate, `Ctrl-w H/J/K/L` *swap* views
- `Ctrl-w q` close, `Ctrl-w o` close all but current
- `Ctrl-w n s` / `Ctrl-w n v` split into a new scratch buffer

`vim-tmux-navigator` deliberately does **not** forward `C-h/j/k/l` into helix, so those jump tmux
panes and split navigation inside helix uses `Ctrl-w h/j/k/l`. See the comment in `tmux.conf`.

Jumps:

- `Ctrl-i` / `Ctrl-o` forward / back in the jumplist (`tab` == `Ctrl-i`)
- `space m` push the current selection onto the jumplist (this is the mark substitute)
- `space j` jumplist picker, `g.` go to the last modification

Scroll / view:

- `Ctrl-d` / `Ctrl-u` half page, `Ctrl-f` / `Ctrl-b` full page
- `z` view submenu (`zz` center, `zt` top, `zb` bottom); `Z` is the same but **sticky** — stays open
  so `Zjjjj` scrolls repeatedly

---

## Insert mode (all defaults)

Worth knowing because leaving insert mode to do these is the slow path:

- `Ctrl-r <reg>` insert a register — `Ctrl-r "` pastes the yank register inline
- `Ctrl-x` force the completion menu
- `Ctrl-w` / `A-backspace` delete word back, `A-d` delete word forward
- `Ctrl-u` kill to line start, `Ctrl-k` kill to line end
- `tab` is `smart_tab` (indents at line start, moves through the completion menu otherwise);
  `S-tab` always inserts a literal tab

---

## My rebinds

Current `config.toml`, and what each one costs:

| Binding | Mode | Replaces | Verdict |
|---|---|---|---|
| `C-s` = `:w` | normal | `save_selection` | Standard. `save_selection` is back on `space m`, so nothing is actually lost now. |
| `C-s` = `:w` + `normal_mode` | insert | `commit_undo_checkpoint` | Save without leaving insert. Minor undo-granularity cost. |
| `esc` = collapse + keep-primary | normal | plain `esc` | **Essential.** The single most important vim-refugee rebind. |
| `K` = `hover` | normal | `keep_selections` | Matches vim LSP muscle memory. `keep_selections` is still on `:keep-selections <regex>`. |
| `A-j` / `A-k` = move line down / up | normal + select | `A-j`/`A-k` unbound in normal | Matches VS Code Alt-↓/↑. Keep both modes — select mode handles multi-line ranges. |
| `C-e` / `C-y` = scroll down / up | normal | `C-e` unbound, `C-y` unbound | Vim scroll muscle memory. |
| `>` / `<` + collapse | select | dangling selection after indent | Quality of life. |
| `g o` = `flip_selections` | normal + select | unbound | Cheap addition. |
| `space m` = `save_selection` | normal + select | unbound | Gives back what `C-s` = `:w` took. |
| `space q` / `space Q` = buffer close / close-others | normal | unbound | Beats typing `:bc<ret>`. |
| `space l` / `space L` = `:lsp-restart` / `:log-open` | normal | unbound | The two commands this doc says waste the most time. |
| `=` = `:format` | normal + select | `format_selections` | Uses the `languages.toml` formatter instead of LSP range formatting. See the table under *Format* — the default is correct in exactly one configured language and silently wrong in four. |
| `space =` = `:format` | normal | unbound | Leader alias for the above; drop it if `=` is enough. Deliberately not `space c f` — `space c` is `toggle_comments` and a submenu there would shadow it. |
| `space t …` = toggle submenu | normal | unbound | `space t` was free. Wrap, line numbers, inlay hints, indent guides. |

`S-h` / `S-l` for buffer nav are commented out and should stay that way — `gn` / `gp` are the
defaults for buffer cycling, so the rebind was never needed.

---

## Alt-key chain (Ghostty + tmux)

Working end to end:

- Ghostty: `macos-option-as-alt = true`
- tmux: `xterm-keys on`, `extended-keys on`, `extended-keys-format csi-u`, `escape-time 0`

Verify: at a zsh prompt run `cat -v` and press Option-j. Expect `^[j`. If you see `∆`, the chain is
broken somewhere.

The `terminal-features` glob is now widened to cover both:

```
set -as terminal-features 'tmux*:extkeys,xterm*:extkeys'
```

`default-terminal` is `tmux-256color`, so an `xterm*`-only glob never matched what helix sees inside
tmux. Confirm after a reload with `tmux show-options -sg terminal-features`.

`terminal-overrides ",xterm*:Tc"` on line 1 of `tmux.conf` has the same glob problem and is **not**
fixed — helix doesn't care because `true-color = true` overrides detection, but other TUIs in tmux
may fall back to 256 colors. Widen it the same way if a colour looks wrong somewhere else.

---

## Gotchas

- **`R`** replaces the selection with yanked content — it is not vim's replace mode. Per-character
  replace is `r<char>`.
- **`U`** is redo, not vim's revert-line.
- **`J`** leaves the cursor at the join point.
- **`Q`** records, **`q`** replays — inverted from vim.
- **`*`** only sets the search register; follow with `n` to jump like vim's `*`.
- **`f<char>`** goes to the next match only; repeat with `Alt-.` (not `;`, which collapses).
- **No `:s/foo/bar/`** — use the multi-cursor flow, or `space r` for symbol-aware rename.
- **No vim marks** (`ma` / `'a`) — use selection registers (`"a` prefix) and the jumplist
  (`Ctrl-s` to push, `Ctrl-o` / `space j` to return). `Alt-(` / `Alt-)` are *not* this.
- **No folds at all.** `zc` / `zo` / `zR` don't exist and there is no fold implementation in the
  tree (`grep -rn fold helix-term/src/commands*` only hits `Iterator::fold`). Long-standing open
  upstream request; nothing to configure. The substitutes are structural navigation instead of
  hiding: `space s` symbol picker, `]f` / `[f` function motions, `A-o` / `A-i` to grow and shrink
  the tree-sitter selection, `space /` global search.

---

## LSP gotchas

- **`:lsp-restart`** after editing `languages.toml`. helix reloads its config, but running language
  servers don't pick up the change until they're bounced. This is the one that wastes the most time.
- **`:log-open`** is the first stop whenever a server silently does nothing.
- **vtsls and project TypeScript**: vtsls resolves `typescript` from `node_modules/typescript/`
  first and falls back to global. A project with no `node_modules` still works — no need for a
  global `npm i -g typescript`.
- **prettier is the global one**, not the project's pinned version. If a project pins prettier 2.x
  and you're on 3.x, format-on-save can produce diffs `npm run format` wouldn't. Point that
  project's `formatter` at `npx prettier` if it bites. `.prettierrc` discovery is per-project and
  matches VS Code's behavior.
- **Schema URLs go stale**: if `:log-open` shows yaml-language-server failing to fetch a schema,
  the URL in `languages.toml` is what needs updating, not the server.

---

## Useful commands

- `:reload` / `:reload-all` — pick up outside changes
- `:format` — explicit format (or `=` on a selection)
- `:keep-selections <regex>` — the unbound version of what `K` used to do
- `:sort` / `:sort -r`, `:reflow`
- `:pipe <cmd>` / `:pipe-to <cmd>` — typed equivalents of `|` and `A-|`
- `:insert-output <cmd>` / `:append-output <cmd>` — typed equivalents of `!` and `A-!`
- `:run-shell-command <cmd>` — run without touching the buffer (build, test, lint)
- `:yank-diagnostic` — copy the diagnostic message under the cursor
- `:reset-diff-change` — revert the git hunk under the cursor (pairs with `]g` / `[g`)
- `:move <path>` / `:move! <path>` — rename the file on disk *and* tell the LSP
- `:set-register` / `:clear-register`, `:toggle-option`, `:get-option`
- `:set-option <key> <value>` — try any `[editor]` option live before committing it to `config.toml`
- `:set-language <name>` — force a language for the buffer
- `:tree-sitter-subtree` — inspect the parse at the cursor when a query misbehaves
- `:config-reload` — pick up config changes without restarting
- `:log-open` — helix's log; first stop for LSP problems
- `hx --health` / `hx --health <lang>` — which servers and formatters actually resolve
- `hx --config /tmp/test.toml file.txt` — try a config without touching the live one
- `hx --tutor`

---

## Discovery

Press `g`, `m`, or `space` and wait — the submode hint appears which-key style. `space ?` searches
every command by name. `:config-reload` plus a scratch keymap is the fastest binding-iteration loop.

---

## Config notes

Settled, but worth revisiting if something feels wrong:

1. **`soft-wrap enable = true`** — unusual for code, good for prose. `space t w` flips it live
   (globally — there's no per-buffer wrap), so leaving it on costs nothing.
2. **`scrolloff = 8` with `bufferline = "multiple"`** — tight on short terminals, fine full-height.
3. **`completion-trigger-len = 3` + `completion-timeout = 5`** — trigger-len was raised from 2
   because the popup was noisy; that's the right knob for noise. The 250ms default timeout then had
   nothing left to do but add lag, so it's down to 5ms (the value the option's own docstring
   suggests for "instant").
4. **`[editor.word-completion] trigger-length = 5`** — helix enables buffer-word completion by
   default at length 7, which is long enough that it never fires in practice. 5 makes it useful in
   files with no language server. Raise it back if it starts competing with LSP completions.
5. **`auto-save = { focus-lost = true }`** — saves when helix loses focus, which includes tmux pane
   switches because `focus-events on` is set in `tmux.conf`. **`after-delay` is deliberately off**:
   `auto-format = true` is set for most languages here, so a delay-triggered save would reformat
   the buffer mid-thought. `C-s` stays.
6. **`[editor.inline-diagnostics] cursor-line = "warning"`** — long rustc/tsc messages render as
   virtual text under the cursor line instead of being truncated at EOL. Anything below `warning`
   still goes to EOL via `end-of-line-diagnostics = "hint"`; there's no double render, because
   `InlineDiagnostics::render_virt_lines` filters a diagnostic out of the EOL set once it's shown
   inline. `other-lines` stays disabled — virtual text on non-cursor lines shifts the viewport as
   you move.
7. **`jump-label-alphabet`** — reordered from `a..z` into typing order so the first `gw` labels land
   under your fingers. Parsed as a **string**, not a list (`deserialize_alphabet` in
   `helix-view/src/editor.rs`), and duplicate characters are a hard error.
8. **`trim-trailing-whitespace` / `trim-final-newlines`** — the formatters in `languages.toml` cover
   most languages; this catches the ones without one.
9. **`text-width = 100` + `rulers = [100]`** — matches the Python line length in
   `~/.config/ruff/pyproject.toml` only loosely; ruff's default is 88. Not worth unifying unless
   the ruler starts lying to you.
10. **`default-yank-register = "+"`** — commented out. Uncomment if `space y` gets annoying, but
    then every delete lands on the system clipboard too.
11. **`theme = "catppuccin_mocha"`** — ships inside the runtime tree, matches the tmux theme. If a
    master build drops it, fall back to `base16_default_dark` or pin the tag.

Not enabled, but available in this build if you want them: `rainbow-brackets`, `popup-border`,
`[editor.buffer-picker] start-position = "previous"`, `[editor.smart-tab] supersede-menu`. Run
`:set-option <key> <value>` to try any of them live.

---

## When stuck

- `space ?` then search the command name
- `:log-open` for anything LSP-shaped
- `git log` in `~/mystuff/helix` before/after a `git pull` that broke something
- Defaults change between releases — read `helix-term/src/keymap/default.rs` in the checkout rather
  than trusting docs (including this one)
