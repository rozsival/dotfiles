# shellcheck shell=bash
# Login shells (Ghostty, herdr panes, `ssh host`) read only this file. Route them
# through ~/.bashrc so login and non-login shells end up identical.
# shellcheck source=.bashrc
[ -r "$HOME/.bashrc" ] && . "$HOME/.bashrc"
