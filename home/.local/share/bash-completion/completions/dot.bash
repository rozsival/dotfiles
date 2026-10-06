# shellcheck shell=bash
# Completion for `dot` (bin/dot). bash-completion's lazy loader looks in
# ~/.local/share/bash-completion/completions before its own Graphviz `dot`
# completion. The adapter comes from the CLI itself (bashly runtime completions)
# and asks `dot __complete <words>` for candidates, so commands, flags and
# vault.list titles stay current without editing this file.
eval "$(dot completions 2>/dev/null)"
