#!/bin/bash
# Fresh-Mac entry point. Run it as
#
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/rozsival/dotfiles/main/install.sh)"
#
# not `curl | bash`: the installers it starts read the terminal, and with a pipe
# they would read this script instead. Gets git (Xcode Command Line Tools),
# clones the repo over HTTPS (no keys exist yet), installs Homebrew and its bash
# - bin/dot is a bashly script and needs bash 4.2+ - and hands over to
# `dot setup`. Runs under macOS's /bin/bash 3.2.
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/projects/rozsival/dotfiles}"
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/rozsival/dotfiles.git}"
HOMEBREW_PREFIX=/opt/homebrew

[ "$(uname -s)" = Darwin ] || {
  echo 'install.sh: macOS only' >&2
  exit 1
}
[ "$(uname -m)" = arm64 ] || {
  echo "install.sh: Apple Silicon only: paths assume $HOMEBREW_PREFIX" >&2
  exit 1
}

if ! xcode-select -p >/dev/null 2>&1; then
  echo '==> Installing Xcode Command Line Tools: finish the dialog, this waits for it'
  xcode-select --install >/dev/null 2>&1 || true
  until xcode-select -p >/dev/null 2>&1; do sleep 5; done
fi

if [ ! -d "$DOTFILES_DIR/.git" ]; then
  mkdir -p "$(dirname "$DOTFILES_DIR")"
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

if [ ! -x "$HOMEBREW_PREFIX/bin/brew" ]; then
  echo '==> Installing Homebrew'
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$("$HOMEBREW_PREFIX/bin/brew" shellenv)"
[ -x "$HOMEBREW_PREFIX/bin/bash" ] || HOMEBREW_NO_ASK=1 brew install bash

exec "$HOMEBREW_PREFIX/bin/bash" "$DOTFILES_DIR/bin/dot" setup
