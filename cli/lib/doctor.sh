## `dot doctor`.

# How a fresh login shell resolves a command (what panes and agents will get),
# independent of the PATH `dot` happened to inherit.
fresh_which() {
  env -i HOME="$HOME" USER="$USER" PATH=/usr/bin:/bin:/usr/sbin:/sbin \
    /bin/bash --noprofile --norc -c '. "$HOME/.config/bash/env.sh" 2>/dev/null; type -P "$1"' _ "$1"
}

# "dir name" for each command Homebrew links whose first hit on that PATH is
# another install. mise shims are meant to win for the runtimes mise manages.
# Builtins only: one shell, no fork per name.
fresh_shadowed() {
  env -i HOME="$HOME" USER="$USER" PATH=/usr/bin:/bin:/usr/sbin:/sbin \
    /bin/bash --noprofile --norc -c '
      . "$HOME/.config/bash/env.sh" 2>/dev/null
      IFS=: read -r -a dirs <<<"$PATH"
      for bin in "$1"/bin/* "$1"/sbin/*; do
        name=${bin##*/}
        for dir in "${dirs[@]}"; do
          [ -x "$dir/$name" ] && [ ! -d "$dir/$name" ] || continue
          case $dir in "$1"/* | "$HOME/.local/share/mise/shims") ;; *) printf "%s %s\n" "$dir" "$name" ;; esac
          break
        done
      done' _ "$HOMEBREW_PREFIX"
}

doctor_system() {
  step System
  ok "macOS $(sw_vers -productVersion) ($(sw_vers -buildVersion)), $(uname -m)"
  xcode-select -p >/dev/null 2>&1 && ok 'Xcode Command Line Tools' || {
    bad 'Xcode Command Line Tools missing'
    hint 'xcode-select --install'
  }
  if brew_env; then
    if brew bundle check --file "$DOTFILES/Brewfile" --no-upgrade >/dev/null 2>&1; then
      ok 'Brewfile satisfied'
    else
      bad 'Brewfile not satisfied'
      hint 'dot brew --check lists what is missing; run dot brew in your own terminal (casks may ask for Touch ID; granting Ghostty App Management avoids it)'
    fi
    if brew bundle check --file "$DOTFILES/Brewfile.mas" --no-upgrade >/dev/null 2>&1; then
      ok 'App Store apps (Brewfile.mas)'
    else
      warn 'App Store apps missing'
      hint 'sign in to the App Store app, then: dot brew --mas'
    fi
  else
    bad 'Homebrew missing'
    hint "re-run install.sh: bin/dot itself needs Homebrew's bash"
  fi
  [ "$(login_shell)" = "$HOMEBREW_PREFIX/bin/bash" ] && ok "login shell $HOMEBREW_PREFIX/bin/bash" || {
    bad "login shell is $(login_shell)"
    hint 'dot setup'
  }
  # `grep >/dev/null`, never `grep -q`, after a pipe: -q exits on the first
  # match, the writer dies of SIGPIPE, and pipefail turns a pass into a fail.
  fdesetup status | grep 'FileVault is On' >/dev/null && ok FileVault || {
    bad 'FileVault off'
    hint 'System Settings -> Privacy & Security -> FileVault'
  }
  csrutil status | grep enabled >/dev/null && ok 'System Integrity Protection' || bad 'SIP disabled: re-enable from Recovery (csrutil enable)'
  grep -qs '^auth[[:space:]].*pam_tid.so' /etc/pam.d/sudo_local && ok 'Touch ID for sudo' || {
    warn 'Touch ID for sudo off'
    hint 'dot setup'
  }
  local drift
  if drift="$("$DOTFILES/macos/defaults.sh" --check 2>&1)"; then
    ok 'macOS defaults'
  else
    bad "macOS defaults: $(printf '%s\n' "$drift" | tail -1)"
    hint 'dot macos --check shows each; dot macos applies them'
  fi
}

doctor_dotfiles() {
  step Dotfiles
  local src rel missing=0 dirty ms
  while IFS= read -r -d '' src; do
    rel=${src#"$DOTFILES/home/"}
    [ "$(readlink "$HOME/$rel" 2>/dev/null)" = "$src" ] || {
      missing=$((missing + 1))
      info "not linked: ~/$rel"
    }
  done < <(find "$DOTFILES/home" \( -type f -o -type l \) ! -name .DS_Store -print0)
  [ $missing = 0 ] && ok 'home/ linked into ~' || {
    bad "$missing file(s) not linked"
    hint 'dot link'
  }
  while IFS= read -r -d '' src; do
    rel=${src#"$DOTFILES/seed/"}
    [ -e "$HOME/$rel" ] || {
      bad "seed missing: ~/$rel"
      hint 'dot link'
    }
  done < <(find "$DOTFILES/seed" -type f ! -name .DS_Store -print0)
  dirty="$(git -C "$DOTFILES" status --porcelain -- home seed 2>/dev/null)"
  if [ -n "$dirty" ]; then
    warn 'tracked dotfiles changed in place (an installer edited a linked file?)'
    printf '%s\n' "$dirty" | sed 's/^/      /'
    hint "git -C $(tilde "$DOTFILES") diff: commit what belongs, move machine-only lines to ~/.config/bash/local.sh"
  fi
  doctor_upstream
  ms="$("$HOMEBREW_PREFIX/bin/bash" -c 's=$EPOCHREALTIME; "$BASH" -lic exit </dev/null >/dev/null 2>&1; e=$EPOCHREALTIME; echo $(( (${e/./} - ${s/./}) / 1000 ))' 2>/dev/null || echo '?')"
  if [ "$ms" != '?' ] && [ "$ms" -lt 400 ]; then ok "shell startup ${ms} ms"; else warn "shell startup ${ms} ms (target < 400)"; fi
}

# Unpushed commits stay on this Mac only; unpulled ones never reach it.
doctor_upstream() {
  local counts ahead behind
  # Doctor runs from agent shells too: fail instead of waiting on a prompt no one sees.
  # An inherited GIT_SSH_COMMAND wins: devbox launchers set one to keep agents off your SSH keys.
  if ! GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh -o BatchMode=yes}" git -C "$DOTFILES" fetch --quiet 2>/dev/null; then
    warn 'could not fetch the dotfiles repo from origin'
    return
  fi
  if ! counts="$(git -C "$DOTFILES" rev-list --left-right --count 'HEAD...@{upstream}' 2>/dev/null)"; then
    warn 'dotfiles branch has no upstream'
    hint "git -C $(tilde "$DOTFILES") branch --set-upstream-to origin/main"
    return
  fi
  ahead=${counts%%[[:space:]]*}
  behind=${counts##*[[:space:]]}
  [ "$ahead" = 0 ] && [ "$behind" = 0 ] && ok 'dotfiles repo in sync with origin'
  [ "$ahead" = 0 ] || {
    warn "dotfiles repo $ahead commit(s) ahead of origin"
    hint "git -C $(tilde "$DOTFILES") push"
  }
  [ "$behind" = 0 ] || {
    warn "dotfiles repo $behind commit(s) behind origin"
    hint 'dot sync'
  }
}

doctor_identity() {
  step '1Password, keys, git'
  [ -d /Applications/1Password.app ] && ok '1Password app' || bad '1Password app missing'
  if [ -S "$OP_AGENT_SOCK" ]; then ok '1Password SSH agent'; else
    bad '1Password SSH agent socket missing'
    hint '1Password -> Settings -> Developer -> Use the SSH agent'
  fi
  if have op && op account list 2>/dev/null | grep -F "$DOT_OP_ACCOUNT" >/dev/null; then ok "op CLI knows $DOT_OP_ACCOUNT"; else
    bad "op CLI not connected to $DOT_OP_ACCOUNT"
    hint '1Password -> Settings -> Developer -> Integrate with 1Password CLI'
  fi
  local title path mode actual
  while read -r title path mode; do
    path=${path/#\~/$HOME}
    if [ ! -f "$path" ]; then
      bad "vault file missing: $(tilde "$path")"
      hint "dot vault pull $title"
    elif actual="$(/usr/bin/stat -f %Lp "$path")" && [ "$actual" != "$mode" ]; then
      bad "$(tilde "$path") is mode $actual, want $mode"
      hint "chmod $mode $(tilde "$path")"
    fi
  done < <(vault_entries)
  local keys
  keys="$(grep -l 'PRIVATE KEY' "$HOME"/.ssh/* 2>/dev/null || true)"
  if [ -n "$keys" ]; then
    bad "private key on disk: $(printf '%s' "$keys" | tr '\n' ' ')"
    hint 'import it into 1Password as an SSH Key item, keep only the .pub, delete the file'
  else
    ok 'no private keys in ~/.ssh'
  fi
  if [ ! -r "$IDENTITIES_LIB" ]; then
    bad 'devbox-identities missing'
    hint "git clone $DEVBOX_REPO $(tilde "$DEVBOX_DIR") && cd $(tilde "$DEVBOX_DIR") && ./bin/devbox agent install"
  elif [ ! -r "$HOME/.config/devbox/identities.conf" ]; then
    bad 'no identities.conf'
    hint 'dot vault pull devbox/identities.conf'
  else
    local slug pub
    for slug in $("$IDENTITIES_LIB" list); do
      for pub in "id_$slug.pub" "signing_$slug.pub"; do
        [ -f "$HOME/.ssh/$pub" ] || {
          bad "missing ~/.ssh/$pub"
          hint 'dot identities writes it from identities.conf'
        }
      done
    done
    # Subshell: its `die` paths must not end the doctor run.
    if (identities_sync 1) >/dev/null 2>&1; then ok 'git + ssh identity config rendered and current'; else
      bad 'identity config missing or stale'
      hint 'dot identities'
    fi
  fi
  [ -f "$HOME/.ssh/devbox.pub" ] && ok 'devbox key: ~/.ssh/devbox.pub' || {
    bad 'missing ~/.ssh/devbox.pub'
    hint '1Password item "Devbox Laptop" -> public key -> ~/.ssh/devbox.pub'
  }
  # The real gh: in an agent session the devbox shim answers with its PAT.
  if [ -x "$HOMEBREW_PREFIX/bin/gh" ] && env -u GH_TOKEN -u GH_CONFIG_DIR "$HOMEBREW_PREFIX/bin/gh" auth status --hostname github.com >/dev/null 2>&1; then ok 'gh signed in (human login)'; else
    bad 'gh not signed in'
    hint 'run yourself: gh auth login --hostname github.com --git-protocol ssh --web'
  fi
}

doctor_devbox() {
  step 'Tailscale & devbox'
  local ts=/Applications/Tailscale.app/Contents/MacOS/Tailscale
  if [ -x "$ts" ] && [ "$("$ts" status --json 2>/dev/null | jq -r .BackendState 2>/dev/null)" = Running ]; then ok 'Tailscale connected'; else
    bad 'Tailscale not connected'
    hint 'open Tailscale, log in, approve this device'
  fi
  [ -d "$DEVBOX_DIR/.git" ] && ok "devbox repo at $(tilde "$DEVBOX_DIR")" || {
    bad 'devbox repo missing'
    hint "git clone $DEVBOX_REPO $(tilde "$DEVBOX_DIR")"
  }
  [ -L "$HOME/.local/bin/devbox" ] && [ "$HOME/.local/bin/devbox" -ef "$DEVBOX_DIR/bin/devbox" ] && ok 'devbox command on the PATH' || {
    bad "$(tilde "$HOME/.local/bin/devbox") is not a link to $(tilde "$DEVBOX_DIR")/bin/devbox"
    hint "cd $(tilde "$DEVBOX_DIR") && ./bin/devbox install"
  }
  # deploy and doctor laptop take the workstation alias from the checkout's
  # gitignored .push.env, so a new Mac starts without it.
  grep -q '^DEVBOX_HOST=.' "$DEVBOX_DIR/.push.env" 2>/dev/null && ok 'devbox .push.env names the workstation' || {
    bad "no DEVBOX_HOST in $(tilde "$DEVBOX_DIR")/.push.env"
    hint "echo 'DEVBOX_HOST=panther-minor' >$(tilde "$DEVBOX_DIR")/.push.env"
  }
  local cmd want got
  for cmd in omp claude; do
    want="$HOME/.local/libexec/devbox-agent/launchers/$cmd"
    got="$(fresh_which "$cmd" || true)"
    if [ "$got" = "$want" ]; then ok "$cmd -> devbox launcher"; else
      bad "$cmd resolves to ${got:-nothing}, not the devbox launcher"
      hint "cd $(tilde "$DEVBOX_DIR") && ./bin/devbox agent install"
    fi
  done
  if have herdr && herdr machine list 2>/dev/null | awk -F'\t' '$3 == "devbox"' | grep . >/dev/null; then ok 'herdr machine devbox'; else
    bad 'herdr has no devbox machine'
    hint 'ssh devbox true && herdr machine add devbox --label Devbox'
  fi
  info 'end-to-end keys, tokens and connections: ./bin/devbox doctor laptop (in the devbox repo)'
}

doctor_agents() {
  step 'Agents & tools'
  local bin
  bin="$(real_omp)" && ok "omp $("$bin" --version 2>/dev/null | head -1)" || {
    bad 'omp missing'
    hint 'dot setup'
  }
  # Exit status only: the token itself must never reach the output. Skipped
  # without omp: 'omp missing' already names the fix.
  if [ -n "$bin" ]; then
    if "$bin" token anthropic </dev/null >/dev/null 2>&1; then ok 'omp signed in to Anthropic'; else
      bad 'omp not signed in to Anthropic'
      hint 'omp login anthropic   (Claude Pro/Max subscription)'
    fi
  fi
  [ -x "$HOME/.local/bin/claude" ] && ok "claude $("$HOME/.local/bin/claude" --version 2>/dev/null | head -1)" || {
    bad 'claude missing'
    hint 'dot setup'
  }
  # /login records the account (no secret) in ~/.claude.json; the token itself
  # sits in the Keychain, which doctor does not touch.
  if [ -x "$HOME/.local/bin/claude" ]; then
    if jq -e '.oauthAccount | type == "object"' "$HOME/.claude.json" >/dev/null 2>&1; then ok 'claude signed in (/login)'; else
      bad 'claude not signed in'
      hint 'claude, then /login and /exit'
    fi
  fi
  if have codex; then
    if codex login status </dev/null >/dev/null 2>&1; then ok 'codex signed in'; else
      bad 'codex not signed in'
      hint 'codex login'
    fi
  fi
  # OMP's bash.patterns guardrail is devbox's (home/.omp/agent/config.yml);
  # the seed and the live file carry copies, and `devbox sync omp` pushes the
  # live one over the devbox's. Neither installer merges into an existing file.
  local tpl="$DEVBOX_DIR/home/.omp/agent/config.yml" copy
  if [ -r "$tpl" ]; then
    for copy in "$DOTFILES/seed/.omp/agent/config.yml" "$HOME/.omp/agent/config.yml"; do
      [ -r "$copy" ] || continue
      if [ "$(omp_guardrail "$copy")" = "$(omp_guardrail "$tpl")" ]; then ok "OMP guardrail current: $(tilde "$copy")"; else
        warn "OMP guardrail in $(tilde "$copy") differs from devbox's"
        hint "replace its bash: block with the one in $(tilde "$tpl")"
      fi
    done
  fi
  [ -x "$HOME/.local/bin/agent-browser" ] && ok agent-browser || bad 'agent-browser missing'
  local pair skill
  for pair in $SKILLS; do
    skill=${pair#*:}
    [ -d "$HOME/.agents/skills/$skill" ] || bad "skill $skill missing"
  done
  if have mise && mise exec -- node --version >/dev/null 2>&1; then ok "node $(mise exec -- node --version) via mise"; else
    bad 'no Node from mise'
    hint 'mise install'
  fi
  # A standalone installer's copy ahead of Homebrew's on the PATH runs while
  # `brew upgrade` updates the one nobody runs.
  local shadowed dir names
  shadowed="$(fresh_shadowed)"
  if [ -z "$shadowed" ]; then ok 'no other installs shadow Homebrew commands'; else
    while read -r dir names; do
      warn "$(tilde "$dir") shadows Homebrew's $names"
    done < <(printf '%s\n' "$shadowed" | awk '{ a[$1] = a[$1] " " $2 } END { for (d in a) print d a[d] }')
    hint 'uninstall those copies (or move them aside); Homebrew installs and upgrades its own'
  fi
  if brew services list 2>/dev/null | awk '$1 == "moshi-hook" {print $2}' | grep started >/dev/null; then
    if moshi-hook status 2>/dev/null | grep 'status:[[:space:]]*paired' >/dev/null; then ok 'moshi-hook running and paired'; else
      bad 'moshi-hook not paired'
      hint 'Moshi app -> Settings -> Hooks -> token, then: moshi-hook pair --token <token>'
    fi
  else
    bad 'moshi-hook service not running'
    hint 'brew services start moshi-hook'
  fi
  # Docker Desktop at login races launchd's com.docker.socket to recreate
  # /var/run/docker.sock and asks for an admin password on every boot. Its
  # settings file is TCC-protected; the backend log of the last start is not.
  local dlog="$HOME/Library/Containers/com.docker.docker/Data/log/host/com.docker.backend.log" sock
  if [ -r "$dlog" ]; then
    sock="$(grep -o 'should enable default docker socket: *[a-z]*' "$dlog" | tail -1 | awk '{print $NF}')"
    if [ "$sock" = true ]; then
      warn 'Docker Desktop default socket on (admin prompt at every boot)'
      hint 'Docker Desktop -> Settings -> Advanced -> untick "Allow the default Docker socket to be used"'
    elif [ "$sock" = false ]; then
      ok 'Docker Desktop default socket off'
    fi
  fi
}

# The top-level `bash:` block of an OMP config, without comments, blank lines
# or quotes: prettier and OMP each requote YAML scalars their own way.
omp_guardrail() {
  awk '/^bash:/ { on = 1; print; next } on && /^[^[:space:]#]/ { on = 0 } on && !/^[[:space:]]*(#|$)/' "$1" | tr -d "\"'"
}
