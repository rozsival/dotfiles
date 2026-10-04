# shellcheck shell=bash
# Environment for every shell, interactive or not: herdr panes, `ssh host cmd`,
# and the shells agents spawn. No subprocesses and no output here - each
# `brew --prefix` used to cost ~35 ms, so Homebrew paths are spelled out.

export HOMEBREW_PREFIX=/opt/homebrew
export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX"
export MANPATH="$HOMEBREW_PREFIX/share/man${MANPATH+:$MANPATH}:"
export INFOPATH="$HOMEBREW_PREFIX/share/info:${INFOPATH:-}"

# Asserts the order of the listed directories at the front of PATH and keeps
# every other entry behind them, deduplicated. Asserted rather than "prepend if
# missing": a parent process (an app, an IDE, an agent) may already carry
# ~/.local/bin ahead of the devbox launchers, and the launchers must win.
_dot_path() {
  local entry front='' rest='' dirs
  for entry in "$@"; do
    [ -d "$entry" ] && front="$front${front:+:}$entry"
  done
  IFS=: read -ra dirs <<<"$PATH"
  for entry in ${dirs[@]+"${dirs[@]}"}; do
    case ":$front:$rest:" in *":$entry:"*) continue ;; esac
    [ -n "$entry" ] && rest="$rest${rest:+:}$entry"
  done
  export PATH="$front${rest:+:$rest}"
}

# devbox launchers first: `omp`/`claude` must resolve to them, not to the real
# binaries in ~/.local/bin and ~/.bun/bin (devbox docs/git.md, laptop install).
# Inside an agent session the launcher has also put its directory (the `gh`
# token shim) first; a shell started there (`bash -lc`, a pane it opens) must
# keep it first, while human shells never get it.
# mise shims rather than `mise activate`: they resolve the project's Node per
# invocation, so agent shells that `cd` between repos get the right version.
_dot_shim=
case ":$PATH:" in *":$HOME/.local/libexec/devbox-agent:"*) _dot_shim="$HOME/.local/libexec/devbox-agent" ;; esac
_dot_path \
  ${_dot_shim:+"$_dot_shim"} \
  "$HOME/.local/libexec/devbox-agent/launchers" \
  "$HOME/.local/bin" \
  "$HOME/bin" \
  "$HOME/.local/share/mise/shims" \
  "$HOME/.cargo/bin" \
  "$HOME/.bun/bin" \
  "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin" \
  "$HOMEBREW_PREFIX/opt/gnu-sed/libexec/gnubin" \
  "$HOMEBREW_PREFIX/opt/llvm/bin" \
  "$HOMEBREW_PREFIX/opt/openjdk/bin" \
  "$HOMEBREW_PREFIX/opt/rustup/bin" \
  "$HOMEBREW_PREFIX/bin" \
  "$HOMEBREW_PREFIX/sbin" \
  "$HOMEBREW_PREFIX/share/google-cloud-sdk/bin"
unset -f _dot_path
unset _dot_shim
# Docker Desktop's user-mode CLI dir goes last, where its installer puts it.
case ":$PATH:" in *":$HOME/.docker/bin:"*) ;; *) [ -d "$HOME/.docker/bin" ] && PATH="$PATH:$HOME/.docker/bin" ;; esac

export EDITOR=nano
export VISUAL=nano
export PAGER=less
export MANPAGER='less -X'

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

export NODE_REPL_HISTORY="$HOME/.node_history"
export NODE_REPL_HISTORY_SIZE=32768

# Native toolchain: Homebrew LLVM and OpenJDK instead of Apple's.
export CC="$HOMEBREW_PREFIX/opt/llvm/bin/clang"
export CXX="$HOMEBREW_PREFIX/opt/llvm/bin/clang++"
export MACOSX_DEPLOYMENT_TARGET=14.0
export JAVA_HOME="$HOMEBREW_PREFIX/opt/openjdk/libexec/openjdk.jdk/Contents/Home"
