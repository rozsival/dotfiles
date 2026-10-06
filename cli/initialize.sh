## Globals for every command. Runs after bashly's strict mode and the defaults of
## the environment variables in bashly.yml; `dot __complete` skips it.
DOTFILES="$(dotfiles_root)"
# bashly's `dot --version` prints this: the commit this checkout is at.
version="$(git -C "$DOTFILES" log -1 --format='%h (%cs)' 2>/dev/null || true)"
HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"
# Homebrew 7 asks before installing by default; `dot` runs unattended and from agents.
export HOMEBREW_NO_ASK=1
# Homebrew retries a refused cask step (macOS App Management) under sudo; without
# a terminal, as in an agent's shell, that waits on a Touch ID prompt no one sees.
# Fail instead: the app in /Applications stays untouched and unadopted until
# `dot brew` runs in a terminal. Safe because no Brewfile cask ships two apps -
# one that did could lose its first, already adopted app in Homebrew's rollback.
[ -t 0 ] || export HOMEBREW_NO_SUDO=1
DEVBOX_REPO=https://github.com/rozsival/devbox.git
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles"
IDENTITIES_LIB="$HOME/.local/libexec/devbox-identities"
OP_AGENT_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
OP_SSH_SIGN=/Applications/1Password.app/Contents/MacOS/op-ssh-sign
# Same pins as devbox's container/skills.sh, so laptop and devbox agents match.
SKILLS_CLI_VERSION=1.5.26
AGENT_BROWSER_VERSION=0.37.1
SKILLS="vercel-labs/agent-browser:agent-browser anthropics/skills:skill-creator vercel-labs/skills:find-skills herdrdev/herdr:herdr max-sixty/worktrunk:worktrunk"
GCLOUD_COMPONENTS='gke-gcloud-auth-plugin alpha beta cloud-sql-proxy'

if [ -t 1 ]; then
  B=$'\033[1m' RED=$'\033[31m' GRN=$'\033[32m' YEL=$'\033[33m' DIM=$'\033[2m' RST=$'\033[0m'
else
  B='' RED='' GRN='' YEL='' DIM='' RST=''
fi
FAILS=0
WARNS=0
