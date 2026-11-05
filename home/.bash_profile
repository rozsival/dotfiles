# The following lines were added by Docker Desktop to add commands to your PATH.
export PATH="$PATH:/Users/vitrozsival/.docker/bin"
# End of Docker Desktop section.

# shellcheck shell=bash
# Login shells (Ghostty, herdr panes, `ssh host`) read only this file. Route them
# through ~/.bashrc so login and non-login shells end up identical.
# shellcheck source=.bashrc
[ -r "$HOME/.bashrc" ] && . "$HOME/.bashrc"
