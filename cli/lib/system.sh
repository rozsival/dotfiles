## Homebrew, shell and agent install lookups.

brew_env() {
  [ -x "$HOMEBREW_PREFIX/bin/brew" ] || return 1
  eval "$("$HOMEBREW_PREFIX/bin/brew" shellenv)"
}

# The PATH an interactive shell gets, so later steps find mise shims, the real
# OMP and Claude installs, and the devbox launchers once they exist.
shell_env() {
  # shellcheck source=home/.config/bash/env.sh
  . "$DOTFILES/home/.config/bash/env.sh"
}

login_shell() { dscl . -read "/Users/$USER" UserShell | awk '{print $2}'; }

real_omp() {
  local bin
  for bin in "$HOME/.bun/bin/omp" "$HOME/.local/bin/omp"; do
    [ -x "$bin" ] && {
      printf '%s' "$bin"
      return 0
    }
  done
  return 1
}
