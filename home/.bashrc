# shellcheck shell=bash
# Every bash lands here: interactive panes, and via ~/.bash_profile login shells.
# The environment is set for all of them; prompt, completion and aliases only
# for interactive ones.

# shellcheck source=.config/bash/env.sh
. "$HOME/.config/bash/env.sh"

case $- in
*i*) ;;
*) return 0 ;;
esac

# shellcheck source=.config/bash/interactive.sh
. "$HOME/.config/bash/interactive.sh"
# shellcheck source=.config/bash/aliases.sh
. "$HOME/.config/bash/aliases.sh"

# Untracked, per-machine additions. Installers that insist on editing an rc file
# should be pointed here instead of at the tracked files.
# shellcheck source=/dev/null
[ -r "$HOME/.config/bash/local.sh" ] && . "$HOME/.config/bash/local.sh"
