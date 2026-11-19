# shellcheck shell=bash
# Login shells (Ghostty, herdr panes, `ssh host`) read only this file. Route them
# through ~/.bashrc so login and non-login shells end up identical.
# Seeded, not linked: installers (Docker Desktop on every start) append to it, so
# it lives on the machine. Seeds never update: keep it this one-line trampoline.
# shellcheck source=../home/.bashrc
[ -r "$HOME/.bashrc" ] && . "$HOME/.bashrc"
