# shellcheck shell=bash
# Interactive shells only: history, prompt, completion.

shopt -s autocd cdspell checkwinsize globstar histappend nocaseglob

# Shared across herdr panes: append each command as it runs, not at exit.
HISTSIZE=32768
HISTFILESIZE=$HISTSIZE
HISTCONTROL=ignoreboth
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

if [ -t 0 ]; then
  GPG_TTY=$(tty)
  export GPG_TTY
fi

# Lazy-loads the per-command completions Homebrew formulae ship (git, gh, wt,
# herdr, mise, uv, ...), so only what is actually completed costs anything.
# shellcheck source=/dev/null
[ -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ] && . "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"

# Init scripts that tools only print at runtime, cached because generating them
# is slow (`omp completions bash` alone took 515 ms per shell). A cache is
# rebuilt when its binary is newer than it; `dot update` clears them all.
# $1 cache name, $2 binary path, rest: the command printing the script.
_dot_cached() {
  local bin=$2 cache="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/$1.bash"
  shift 2
  [ -x "$bin" ] || return 0
  if [ ! -s "$cache" ] || [ "$bin" -nt "$cache" ]; then
    mkdir -p "${cache%/*}"
    "$@" >"$cache.$$" 2>/dev/null && mv "$cache.$$" "$cache" || {
      rm -f "$cache.$$"
      return 0
    }
  fi
  # shellcheck disable=SC1090 # generated at runtime
  . "$cache"
}

# The real OMP, not the devbox launcher in front of it on PATH: the launcher's
# mtime never changes when OMP updates. Its installer picks either directory.
for _dot_omp in "$HOME/.bun/bin/omp" "$HOME/.local/bin/omp"; do
  [ -x "$_dot_omp" ] && _dot_cached omp "$_dot_omp" "$_dot_omp" completions bash && break
done
unset _dot_omp
# The `wt` shell wrapper is what lets `wt switch` change this shell's directory.
_dot_cached wt "$HOMEBREW_PREFIX/bin/wt" "$HOMEBREW_PREFIX/bin/wt" config shell init bash
_dot_cached npm "$HOME/.local/share/mise/shims/npm" "$HOME/.local/share/mise/shims/npm" completion
_dot_cached starship "$HOMEBREW_PREFIX/bin/starship" "$HOMEBREW_PREFIX/bin/starship" init bash --print-full-init
unset -f _dot_cached
