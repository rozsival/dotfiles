local harness="${args[harness]}" bin=''
case "$harness" in
omp) bin="$(real_omp)" || true ;;
claude) bin="$HOME/.local/bin/claude" ;;
esac
[ -n "$bin" ] && [ -x "$bin" ] || die "$harness is not installed: dot setup"
cd "$DOTFILES"
# The real binary, not the devbox launcher: this session acts as you, and the
# launcher's agent git override may not even be installed yet.
exec "$bin" "$(cat "$DOTFILES/setup/PROMPT.md")"
