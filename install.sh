#!/bin/bash
# Fresh-Mac entry point. Run it as
#
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/rozsival/dotfiles/main/install.sh)"
#
# not `curl | bash`: the installers it starts read the terminal, and with a pipe
# they would read this script instead. Gets git (Xcode Command Line Tools),
# clones the repo over HTTPS (no keys exist yet) and hands over to `dot setup`.
# Runs under macOS's /bin/bash 3.2.
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/projects/rozsival/dotfiles}"
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/rozsival/dotfiles.git}"

if ! xcode-select -p >/dev/null 2>&1; then
  echo '==> Installing Xcode Command Line Tools: finish the dialog, this waits for it'
  xcode-select --install >/dev/null 2>&1 || true
  until xcode-select -p >/dev/null 2>&1; do sleep 5; done
fi

if [ ! -d "$DOTFILES_DIR/.git" ]; then
  mkdir -p "$(dirname "$DOTFILES_DIR")"
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

exec "$DOTFILES_DIR/bin/dot" setup
