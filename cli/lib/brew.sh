## `dot brew`.

# $1: '', --mas, --check or --cleanup.
brew_bundle() {
  brew_env || die "Homebrew missing in $HOMEBREW_PREFIX: run install.sh"
  case "${1:-}" in
  '') brew bundle --file "$DOTFILES/Brewfile" ;;
  --mas) brew bundle --file "$DOTFILES/Brewfile.mas" ;;
  --check)
    brew bundle check --file "$DOTFILES/Brewfile" --verbose
    brew bundle check --file "$DOTFILES/Brewfile.mas" --verbose
    ;;
  # Dry run on purpose: lists what `brew bundle cleanup --force` would remove.
  --cleanup) brew bundle cleanup --file "$DOTFILES/Brewfile" ;;
  esac
}
