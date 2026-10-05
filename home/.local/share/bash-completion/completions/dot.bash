# shellcheck shell=bash
# Completion for `dot` (bin/dot). bash-completion's lazy loader looks in
# ~/.local/share/bash-completion/completions before its own Graphviz `dot`
# completion. Commands and options mirror usage() in bin/dot.

# vault.list titles, from the repo the completed `dot` lives in.
_dot_vault_titles() {
  local bin=$1 title _
  [[ $bin == */* ]] || bin=$(type -P -- "$bin") || return 0
  bin=$(readlink -f -- "$bin") || return 0
  [ -r "${bin%/bin/dot}/vault.list" ] || return 0
  while read -r title _; do
    case "$title" in '' | '#'*) ;; *) printf '%s\n' "$title" ;; esac
  done <"${bin%/bin/dot}/vault.list"
}

_dot() {
  local cur=${COMP_WORDS[COMP_CWORD]} words=''
  case "$COMP_CWORD:${COMP_WORDS[1]-}" in
  1:*) words='setup agent doctor link brew macos identities vault sync update help' ;;
  2:agent) words='omp claude' ;;
  2:link) words='--dry-run' ;;
  2:brew) words='--mas --check --cleanup' ;;
  2:macos | 2:identities) words='--check' ;;
  2:vault) words='status pull push' ;;
  *:vault)
    words=$(_dot_vault_titles "${COMP_WORDS[0]}")
    [ "$COMP_CWORD" = 3 ] && [ "${COMP_WORDS[2]}" = pull ] && words="--force $words"
    ;;
  esac
  mapfile -t COMPREPLY < <(compgen -W "$words" -- "$cur")
}

complete -F _dot dot
