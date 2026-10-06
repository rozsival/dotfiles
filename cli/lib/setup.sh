## Steps of `dot setup`.

setup_shell() {
  local bash_path="$HOMEBREW_PREFIX/bin/bash"
  grep -qx "$bash_path" /etc/shells || echo "$bash_path" | sudo tee -a /etc/shells >/dev/null
  [ "$(login_shell)" = "$bash_path" ] || chsh -s "$bash_path"
  ok "login shell $bash_path"
}

setup_runtimes() {
  mise install --yes
  mise reshim
  ok "node $(mise exec -- node --version)"
  if ! rustup default >/dev/null 2>&1; then
    rustup default stable
  fi
  ok "$(rustup default)"
  # The Homebrew cask ships only gcloud/gsutil/bq; kubectl against GKE needs the
  # auth plugin. Installed components land in share/google-cloud-sdk/bin (env.sh).
  # shellcheck disable=SC2086 # a list of component ids, split on purpose
  gcloud components install --quiet $GCLOUD_COMPONENTS
  ok "gcloud components: $GCLOUD_COMPONENTS"
}

setup_agents() {
  real_omp >/dev/null || curl -fsSL https://omp.sh/install.sh | sh
  ok "omp $("$(real_omp)" --version 2>/dev/null | head -1)"
  [ -x "$HOME/.local/bin/claude" ] || curl -fsSL https://claude.ai/install.sh | bash
  ok "claude $("$HOME/.local/bin/claude" --version 2>/dev/null | head -1)"

  # npm's --prefix puts the CLI in ~/.local/bin, independent of which Node mise
  # has active; npm 11 runs no install scripts unless allow-listed.
  if [ ! -x "$HOME/.local/bin/agent-browser" ]; then
    npm install -g --prefix "$HOME/.local" --allow-scripts=agent-browser "agent-browser@$AGENT_BROWSER_VERSION"
    "$HOME/.local/bin/agent-browser" install
  fi
  ok "agent-browser $("$HOME/.local/bin/agent-browser" --version 2>/dev/null)"

  # ~/.agents/skills is what OMP reads; `--agent claude-code` symlinks each into
  # ~/.claude/skills for Claude Code (devbox container/skills.sh does the same).
  local pair repo skill
  for pair in $SKILLS; do
    repo=${pair%%:*} skill=${pair#*:}
    if [ ! -d "$HOME/.agents/skills/$skill" ]; then
      npx --yes "skills@$SKILLS_CLI_VERSION" add "$repo" --skill "$skill" --global --agent universal claude-code --yes
    fi
    ok "skill $skill"
  done

  # Phone notifications and approvals: the daemon plus OMP/Claude hooks. Pairing
  # with the Moshi app is a guided step (`moshi-hook pair`).
  brew services start moshi-hook >/dev/null
  [ -f "$HOME/.omp/agent/extensions/moshi-hooks.ts" ] || moshi-hook install --target omp,claude
  ok 'moshi-hook running, hooks installed'
}

setup_touchid() {
  if grep -qs '^auth[[:space:]].*pam_tid.so' /etc/pam.d/sudo_local; then
    ok 'already enabled'
    return
  fi
  # sudo_local survives macOS updates, unlike edits to /etc/pam.d/sudo.
  sed 's/^#auth/auth/' /etc/pam.d/sudo_local.template | sudo tee /etc/pam.d/sudo_local >/dev/null
  ok enabled
}
