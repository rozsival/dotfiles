brew_env || die "Homebrew missing in $HOMEBREW_PREFIX: run install.sh"
shell_env
step Homebrew
attempt brew update
attempt brew upgrade --formula
attempt brew upgrade --cask
attempt brew bundle --file "$DOTFILES/Brewfile"
chatgpt_unquarantine
step mise
attempt mise upgrade --yes
step tenv
attempt tenv --quiet tf use --force-remote --install latest-stable
attempt tenv --quiet tofu use --force-remote --install latest-stable
step OMP
# OMP's installer put bun in ~/.bun and nothing else upgrades it, while each OMP
# release may raise the bun it needs; too old a bun makes `omp update` fall back
# to a standalone binary that bun's next global install collides with.
[ ! -x "$HOME/.bun/bin/bun" ] || attempt "$HOME/.bun/bin/bun" upgrade
# By name, so through the devbox launcher once installed: for `update` it
# drops its own PATH entries and omp's updater finds the real install. The
# real binary run directly finds the launcher symlink first and refuses.
attempt omp update
step 'Claude Code'
attempt "$HOME/.local/bin/claude" update
step Skills
attempt npx --yes "skills@$SKILLS_CLI_VERSION" update --global --yes
step moshi-hook
# A new release needs its hooks rewritten and the daemon restarted.
attempt moshi-hook install --target omp,claude
attempt brew services restart moshi-hook
rm -rf "$CACHE_DIR"
ok 'completion caches cleared; they rebuild in the next shell'
[ $FAILS = 0 ] || printf '\n%s%s✗ %d update step(s) failed%s; the rest ran, see ✗ above\n' "$B" "$RED" "$FAILS" "$RST"
# Last, after the summary: from a herdr pane the restart ends this process.
herdr_restart
[ $FAILS = 0 ]
