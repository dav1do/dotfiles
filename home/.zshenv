. "$HOME/.cargo/env"

# ── Tooling node on PATH, without sourcing nvm.sh ──────────────────────────────
# In .zshenv, not .zshrc, because this is sourced for non-interactive shells too:
# helix and anything it spawns needs prettier and the language servers without
# waiting on the lazy nvm stubs to fire. Costs <1ms; sourcing nvm.sh is ~420ms.
#
# Keep ~/.nvm/alias/default pinned to a concrete version (`nvm alias default
# v26.1.0`). A floating alias ("node", "lts/*") isn't a directory name, so the
# fallback below picks the highest installed version — a guess, not your choice.
#
# A later `nvm use` rewrites this PATH entry rather than stacking on it.
if [[ -d $HOME/.nvm/versions/node ]]; then
  () {
    local root=$HOME/.nvm/versions/node ver
    [[ -r $HOME/.nvm/alias/default ]] && ver=$(<$HOME/.nvm/alias/default)
    # (/N) = directories only, empty on no match; (n) = numeric-aware sort
    [[ -n $ver && -d $root/$ver ]] || ver=${${(f)"$(print -rl -- $root/*(/Nn:t))"}[-1]}
    [[ -n $ver && -d $root/$ver/bin ]] && export PATH="$root/$ver/bin:$PATH"
  }
fi
