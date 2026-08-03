. "$HOME/.cargo/env"

# ── Tooling node on PATH, without sourcing nvm.sh ──────────────────────────────
# This lives in .zshenv, not .zshrc, because .zshenv is sourced for every zsh
# invocation including non-interactive ones. That's the point: helix, and anything
# it spawns, needs prettier and the language servers on PATH without depending on
# the lazy nvm stubs in .zshrc having fired first.
#
# Costs <1ms (measured: 100 iterations in 96ms, against a 3ms bare-zsh baseline).
# Sourcing nvm.sh to get the same effect costs ~420ms.
#
# Resolves ~/.nvm/alias/default. Keep that pinned to a concrete version
# (`nvm alias default v26.1.0`) — a floating alias ("node", "lts/*") isn't a
# directory name, so the fallback below picks the highest installed version
# instead, which is a guess rather than your choice.
#
# `nvm use` later in the session rewrites this PATH entry rather than stacking on
# it (nvm_change_path, nvm.sh:1000), so a project override cleanly replaces the
# default. Tools stay resolvable across the switch because ~/.nvm/default-packages
# installs them into every version.
if [[ -d $HOME/.nvm/versions/node ]]; then
  () {
    local root=$HOME/.nvm/versions/node ver
    [[ -r $HOME/.nvm/alias/default ]] && ver=$(<$HOME/.nvm/alias/default)
    # (/N) = directories only, empty on no match; (n) = numeric-aware sort
    [[ -n $ver && -d $root/$ver ]] || ver=${${(f)"$(print -rl -- $root/*(/Nn:t))"}[-1]}
    [[ -n $ver && -d $root/$ver/bin ]] && export PATH="$root/$ver/bin:$PATH"
  }
fi
