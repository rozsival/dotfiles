# Brings this Mac up to what origin has. Refuses a dirty tree: home/ files are
# live symlink targets, so a merge or stash must never happen behind your back.
local dirty drift
step 'Dotfiles repo'
# Untracked files don't block a fast-forward; git refuses one that would overwrite them.
dirty="$(git -C "$DOTFILES" status --porcelain --untracked-files=no)"
[ -z "$dirty" ] || die "uncommitted changes in $(tilde "$DOTFILES"): commit and push them first"
git -C "$DOTFILES" pull --ff-only
step Links
link_home
step Homebrew
brew_bundle
step 'macOS defaults'
if drift="$("$DOTFILES/macos/defaults.sh" --check 2>&1)"; then
  ok 'macOS defaults'
else
  printf '%s\n' "$drift"
  warn 'macOS defaults drift: dot macos applies them'
fi
