brew_env || die "Homebrew missing in $HOMEBREW_PREFIX: run install.sh"
shell_env
step Homebrew
attempt brew update
attempt brew upgrade --formula
attempt brew upgrade --cask
attempt brew bundle --file "$DOTFILES/Brewfile"
step mise
attempt mise upgrade --yes
step OMP
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
[ $FAILS = 0 ] || {
  printf '\n%s%s✗ %d update step(s) failed%s; the rest ran, see ✗ above\n' "$B" "$RED" "$FAILS" "$RST"
  return 1
}
