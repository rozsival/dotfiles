## The herdr server after Homebrew upgrades herdr.
#
# Homebrew replaces the binary but the running server keeps the old one, and
# clients (Moshi's included) then report a client/server version mismatch.
# Live handoff (`herdr update --handoff`) only exists for herdr's own installer,
# so the one way to the new server is `herdr server stop`: it ends every pane
# process. OMP and Claude panes resume their sessions on the next `herdr`;
# shells and whatever runs in them do not. Hence a question, never automatic.

HERDR_RESTART_HINT='herdr server stop, then herdr (ends every pane process; OMP and Claude sessions resume)'

# The running server's version when it runs a binary older than the installed
# one; empty when it is current, not running, or herdr is missing.
herdr_stale_server() {
  have herdr || return 0
  herdr status --json 2>/dev/null |
    jq -r 'select(.server.running and (.server.server_binary_stale or .server.restart_needed)) | .server.version' 2>/dev/null ||
    true
}

# Offers the restart on a terminal; otherwise, or when declined, names the command.
# Last step of a command: run from a herdr pane, the stop ends this process too.
herdr_restart() {
  local server client answer
  server="$(herdr_stale_server)"
  [ -n "$server" ] || return 0
  client="$(herdr --version | awk '{print $2}')"
  step herdr
  warn "herdr server $server is older than the installed $client; clients report a version mismatch"
  if [ -t 0 ] && [ -t 1 ]; then
    read -r -p "    Restart the herdr server now? Every pane process ends. [y/N] " answer || answer=''
    case "$answer" in
    [yY]*)
      [ "${HERDR_ENV:-}" != 1 ] || info 'this pane is a herdr pane and closes with the server; run herdr to start the new one'
      if herdr server stop >/dev/null; then ok "herdr server stopped; the next herdr starts $client"; else bad '`herdr server stop` failed'; fi
      return 0
      ;;
    esac
  fi
  hint "$HERDR_RESTART_HINT"
}
