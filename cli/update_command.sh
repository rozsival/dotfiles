brew_env || die "Homebrew missing in $HOMEBREW_PREFIX: run install.sh"
shell_env
step Homebrew
brew update
brew upgrade
brew bundle --file "$DOTFILES/Brewfile"
step mise
mise upgrade --yes
step OMP
# By name, so through the devbox launcher once installed: for `update` it
# drops its own PATH entries and omp's updater finds the real install. The
# real binary run directly finds the launcher symlink first and refuses.
omp update
step 'Claude Code'
"$HOME/.local/bin/claude" update
step Skills
npx --yes "skills@$SKILLS_CLI_VERSION" update --global --yes
step moshi-hook
# A new release needs its hooks rewritten and the daemon restarted.
moshi-hook install --target omp,claude
brew services restart moshi-hook
rm -rf "$CACHE_DIR"
ok 'completion caches cleared; they rebuild in the next shell'
