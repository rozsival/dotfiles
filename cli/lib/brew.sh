## `dot brew`, and the cask fix-ups that follow every Homebrew install.

# $1: '', --mas, --check or --cleanup.
brew_bundle() {
  brew_env || die "Homebrew missing in $HOMEBREW_PREFIX: run install.sh"
  case "${1:-}" in
  '')
    brew bundle --file "$DOTFILES/Brewfile"
    chatgpt_unquarantine
    ;;
  --mas) brew bundle --file "$DOTFILES/Brewfile.mas" ;;
  --check)
    brew bundle check --file "$DOTFILES/Brewfile" --verbose
    brew bundle check --file "$DOTFILES/Brewfile.mas" --verbose
    ;;
  # Dry run on purpose: lists what `brew bundle cleanup --force` would remove.
  --cleanup) brew bundle cleanup --file "$DOTFILES/Brewfile" ;;
  esac
}

# ChatGPT copies this helper to ~/.codex/computer-use on every launch, and the
# copy inherits the quarantine Homebrew put on the bundle: Gatekeeper asks again
# each time, since approving marks only the copy the next launch replaces.
# Homebrew 5+ has no --no-quarantine, so each cask upgrade brings it back.
CHATGPT_CUA_HELPER='/Applications/ChatGPT.app/Contents/Resources/cua_node/lib/node_modules/@oai/sky/Codex Computer Use.app'
chatgpt_quarantined() { xattr -p com.apple.quarantine "$CHATGPT_CUA_HELPER" >/dev/null 2>&1; }

# Only that notarized helper, never the whole app; a no-op when it is absent or
# clean. macOS denies the write without App Management (an agent's shell, a
# terminal not granted it): warn, never fail the caller.
chatgpt_unquarantine() {
  chatgpt_quarantined || return 0
  if xattr -dr com.apple.quarantine "$CHATGPT_CUA_HELPER" 2>/dev/null; then
    ok 'ChatGPT Computer Use helper: quarantine cleared'
  else
    warn 'ChatGPT Computer Use helper still quarantined: Gatekeeper asks on every ChatGPT launch'
    hint 'grant your terminal App Management (Privacy & Security), then run dot brew in it'
  fi
}
