## Output and small helpers shared by every command.

# The repo bin/dot lives in, through the ~/.local/bin/dot symlink.
dotfiles_root() { (cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd); }

step() { printf '\n%s==> %s%s\n' "$B" "$*" "$RST"; }
info() { printf '    %s\n' "$*"; }
ok() { printf '  %s✓%s %s\n' "$GRN" "$RST" "$*"; }
warn() {
  printf '  %s!%s %s\n' "$YEL" "$RST" "$*"
  WARNS=$((WARNS + 1))
}
bad() {
  printf '  %s✗%s %s\n' "$RED" "$RST" "$*"
  FAILS=$((FAILS + 1))
}
# Runs a command; a failure is reported and counted, not fatal, so later steps still run.
attempt() {
  local rc=0
  "$@" || rc=$?
  [ $rc = 0 ] || bad "\`$*\` failed (exit $rc)"
}
hint() { printf '    %s→ %s%s\n' "$DIM" "$*" "$RST"; }
die() {
  printf '%sdot: %s%s\n' "$RED" "$*" "$RST" >&2
  exit 1
}
have() { command -v "$1" >/dev/null 2>&1; }
# $HOME as ~, for paths shown to a person.
tilde() {
  local t='~'
  printf '%s' "${1/#"$HOME"/$t}"
}
