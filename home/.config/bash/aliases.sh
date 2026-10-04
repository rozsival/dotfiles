# shellcheck shell=bash
# Kept by usage: everything here has real history behind it. ls is GNU ls
# (coreutils' gnubin is on PATH).

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'
alias p='cd ~/projects'

export LS_COLORS='no=00:fi=00:di=01;31:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.zip=01;31:*.gz=01;31:*.bz2=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.png=01;35:*.mov=01;35:*.mp3=01;35:*.wav=01;35:'
alias ls='ls --color=auto'
alias l='ls -lF'
alias ll='ls -lAF'
alias grep='grep --color=auto'

alias lg='lazygit'
alias reload='exec "$SHELL" -l'
alias path='tr : "\n" <<<"$PATH"'

alias panther-minor-sleep='ssh -f panther-minor "sudo systemctl suspend"'
alias panther-minor-wake='ssh -f pi-zero "wakeonlan 9c:6b:00:c6:4e:0b"'

# Create a directory and enter it.
mkd() { mkdir -p "$@" && cd "${@: -1}" || return; }

# Open the current directory, or the given paths, in Finder / their app.
o() { open "${@:-.}"; }

# `gi tstatus` -> `git status`: the slip shows up 100+ times in history.
gi() {
  case $1 in
  t?*) git "${1#t}" "${@:2}" ;;
  *) git "$@" ;;
  esac
}
