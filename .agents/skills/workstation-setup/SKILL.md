---
name: workstation-setup
description: Guides a person through the parts of setting up this Mac that a script cannot do - 1Password and its SSH agent, restoring secret files from 1Password (`dot vault pull`), devbox's laptop agent tooling, rendering git/ssh identity config (`dot identities`), GitHub login, Tailscale and the devbox connection (herdr, `devbox doctor laptop`), agent logins, Moshi pairing, App Store apps, JetBrains IDEs, cloud CLI logins - driven by `bin/dot doctor` as the acceptance test. Use when setting up a new or reinstalled Mac, when `dot doctor` fails, or when asked what is still missing on this machine.
---

# Workstation setup

`bin/dot doctor` is the acceptance test: every ✗ names a gap and its `→` line the fix. Run it, take
failures in the phase order below (later phases depend on earlier ones), re-run the specific check
after each step, and finish when doctor prints `all checks passed`. Warnings (`!`) are judgement
calls - mention them, fix them if the person agrees.

`install.sh` already installed Xcode CLT, Homebrew and Homebrew bash (`bin/dot` needs it), and `bin/dot
setup` ran: `Brewfile`, Homebrew bash as login shell, `dot link`, mise Node, rustup, OMP, Claude Code,
agent-browser, global skills, moshi-hook service + hooks, Touch ID for sudo, macOS defaults. Re-run a
single piece (`dot brew`, `dot link`, `dot macos`) rather than all of `dot setup`; `dot <command> --help`
lists a command's options.

## Ground rules

- **The person does**: anything in a browser or GUI, every sign-in, every approval (1Password, sudo/Touch
  ID, macOS permission dialogs), and any command that handles a credential (`gh auth login`,
  `moshi-hook pair --token`, `herdr machine add`, `claude` `/login`). Also every `dot` command that can
  prompt for sudo - `dot setup`, `dot brew`, `dot sync`, `dot update`, `dot macos` (apply): an agent shell has no
  terminal, so Homebrew steps that need sudo fail (dot sets `HOMEBREW_NO_SUDO` there) and dot's own sudo
  calls wait on a Touch ID prompt no one sees. Give the exact command or click path,
  wait for confirmation, then verify with a read-only check.
- **Never read secret contents.** Check existence and mode only (`ls -l`, `dot vault status`,
  `dot doctor`) for `~/.config/devbox/secrets.env`, `*/app.pem`, `~/.npmrc`, `~/.omp/agent/models.yml` and
  `~/.omp/agent/.env`. No `op read`, no `op item get --reveal`, no `gh auth token`.
- Not secret, fine to read: `~/.config/devbox/identities.conf` (names, emails, public keys), `.pub`
  files, and `ssh-add -L` against the 1Password agent.
- `dot vault push` overwrites what is in 1Password: ask first.
- Machine-only shell lines go in `~/.config/bash/local.sh`, never in tracked files under `home/`.

The 1Password agent socket, for commands that need it explicitly:
`SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"`.

## Phase 1 - 1Password

Everything after this depends on it. The person:

1. Opens 1Password, signs in to both accounts (personal `my.1password.com`, work `apitree.1password.eu`).
2. Settings → Security: Touch ID on.
3. Settings → Developer: **Use the SSH agent** on, **Integrate with 1Password CLI** on.

Verify: doctor's `1Password SSH agent` and `op CLI knows my.1password.com`; `SSH_AUTH_SOCK=… ssh-add -l`
lists the keys (RSA personal key, ED25519 identity/signing keys, `Devbox Laptop`).

## Phase 2 - restore files from 1Password

`dot vault status` shows each `vault.list` entry: in 1Password, on disk, both, or neither. Then
`dot vault pull` writes the missing ones with their modes (the person approves the 1Password prompt).

- `neither` / `not in vault Workstation` on a first-ever run: those files exist only on the old Mac.
  There, `dot vault push` uploads them (creates the vault if needed). A secret that is truly gone (a
  rotated PAT, a lost App key) is re-issued on GitHub, then saved with `dot vault push <title>`.
- Restores `identities.conf` and `secrets.env` into `~/.config/devbox/` before devbox's installer runs,
  which then keeps them (it never overwrites either).

## Phase 3 - devbox laptop tooling

```bash
git clone https://github.com/rozsival/devbox.git ~/projects/rozsival/devbox   # HTTPS: no SSH key on GitHub yet needed
cd ~/projects/rozsival/devbox && ./bin/devbox agent install
```

Installs the `omp`/`claude` launchers, `gh` shim, credential helper, `devbox-identities`, agent
gitconfigs. The PATH line it prints is already in `~/.config/bash/env.sh` - nothing to add; open a new
shell. Its other printed steps (identities.conf, tokens, App credentials) were covered by phase 2.
Verify: doctor's `omp -> devbox launcher`, `claude -> devbox launcher`.

## Phase 4 - git and ssh identity

```bash
bin/dot identities
```

Renders from `~/.config/devbox/identities.conf`, with devbox's own renderer: `~/.gitconfig` (default
identity, op-ssh-sign signing, `includeIf` per tree and per GitHub org), `~/.config/git/identities/*`,
`~/.ssh/config.d/identities` (GitHub `Host`/`Match … tagged` blocks), `~/.ssh/allowed_signers`, and the
`id_<slug>.pub`/`signing_<slug>.pub` selectors. Shared git settings stay in `~/.config/git/config`
(tracked); never put identity there.

`~/.ssh/devbox.pub` is not in the registry: take it from the agent -
`SSH_AUTH_SOCK=… ssh-add -L | grep 'Devbox Laptop' > ~/.ssh/devbox.pub` (the comment is the item title;
if it differs, list with `ssh-add -L` and ask which line).

Verify: doctor's identity lines; `git -C ~/projects/rozsival/dotfiles config user.email`.

## Phase 5 - GitHub

1. The person runs `gh auth login --hostname github.com --git-protocol ssh --web`.
2. SSH: `ssh -T git@github.com` (personal) and `ssh -P apitree -T git@github.com` (work) each answer
   `Hi <login>!` after a 1Password approval. The keys are the same 1Password items as before, so they
   are already registered on GitHub. Only a brand-new key needs
   `gh ssh-key add ~/.ssh/<file>.pub --type authentication` and, for signing keys, `--type signing` (on the
   right account).
3. Switch this repo and devbox to SSH remotes now that pushing works:
   `git -C <repo> remote set-url origin git@github.com:rozsival/<repo>.git`.
4. Signing check: an empty commit in a scratch repo shows `Good "git" signature` in
   `git log --show-signature -1`.

## Phase 6 - Tailscale and the devbox

1. The person opens Tailscale, logs in, approves the device. Verify: doctor's `Tailscale connected`,
   `tailscale ping panther-minor` (CLI at `/Applications/Tailscale.app/Contents/MacOS/Tailscale`).
2. `ssh devbox true` - the person accepts the host key and approves 1Password.
3. The person runs `herdr machine add devbox --label Devbox` (interactive). Verify: `herdr machine list`.
4. `cd ~/projects/rozsival/devbox && ./bin/devbox doctor laptop` - the end-to-end test for keys, tokens
   and connections. Fix what it names using that repo's `devbox-laptop` skill.

## Phase 7 - agents and phone

- The harness that runs this session is already signed in: `dot agent` needs that first (README quick
  start). The other one: Claude Code - the person runs `claude` and `/login`; OMP - `omp login anthropic`
  (Claude Pro/Max). Codex: `codex login`. Verify: doctor's `omp signed in to Anthropic` and
  `claude signed in (/login)`.
- Moshi for Mac has no cask: the person downloads it from https://getmoshi.app. Pairing: Moshi app →
  Settings → Hooks → token, then the person runs `moshi-hook pair --token <token>`. Verify:
  `moshi-hook status` shows `status: paired`; `moshi-hook doctor`.
- A phone reaching the devbox directly needs its key in `DEVBOX_EXTRA_AUTHORIZED_KEYS` on the
  workstation (devbox `docs/connecting.md`), not on this Mac.

## Phase 8 - apps

- First, the person grants Ghostty **App Management** (System Settings → Privacy & Security → App
  Management). Without it macOS refuses Homebrew's changes to app bundles it did not install (adopting
  an app already in /Applications, upgrading one), and Homebrew falls back to sudo once per app.
- The person runs `bin/dot brew` in their own Ghostty tab. Apps already installed by hand are adopted
  when their version matches the cask; a mismatch fails with "It seems the existing App is different" -
  update the app (or `brew install --cask --force <name>`), then re-run.
- A Mac set up before this repo has standalone copies of what Homebrew now installs (`~/.local/bin`,
  rustup in `~/.cargo/bin`, `~/google-cloud-sdk`, `~/.nvm`, python.org Python). Doctor's "shadows
  Homebrew's" warning lists the ones on the PATH. Move them to `~/.dotfiles-backup/` rather than
  deleting; root-owned ones (python.org, `/usr/local/bin`) are the person's to remove with sudo. First
  rebase what was built on a removed Python: `uv tool install --reinstall --managed-python <tool>`, and
  move `~/.config/gcloud/virtenv` aside so gcloud uses Homebrew's Python.
- Packages the Brewfile does not declare: `bin/dot brew --cleanup` lists them.
  `brew bundle cleanup --force` first resets Homebrew's trust store to the Brewfile, so it cannot uninstall a
  leftover from a third-party tap (and re-trusting before re-running is wiped again). Remove each such
  leftover on its own: `brew trust --formula <tap>/<name> && brew uninstall <name> && brew untap <tap>`
  (untapping also drops the trust entry).
- App Store: the person signs in to the App Store app (`mas` cannot), then `bin/dot brew --mas`. Large (Xcode, Final Cut
  Pro, Logic Pro): confirm before starting.
- No cask, manual download: Moshi (above), Amphetamine Enhancer (from within Amphetamine).
- JetBrains Toolbox: sign in, enable Settings → Tools → Shell scripts → `~/bin`, install the IDEs in
  use (CLion, DataGrip, PyCharm, Rider, RustRover, WebStorm), sign in to each for Settings Sync.
- First runs that need the person: Docker Desktop (accept terms; Settings → Advanced → untick "Allow the
  default Docker socket to be used", else it asks for an admin password at every boot), Rectangle Pro (license,
  Accessibility permission), Google Drive, Slack, Notion, Signal, WhatsApp.
- Login items worth restoring: Rectangle Pro, Pure Paste, Google Drive, Notion Calendar, duet, CodexBar.

## Phase 9 - cloud and package registries (only what the person uses)

`gcloud auth login && gcloud auth application-default login`, `az login`, `kubelogin` /
`az aks get-credentials`, `glab auth login`. `npm whoami` checks the restored `~/.npmrc`.

## Phase 10 - finish

`bin/dot doctor` passes. Remaining warnings are listed for the person with a recommendation. If `git -C
~/projects/rozsival/dotfiles status` shows changes under `home/`, an installer edited a linked file:
show the diff and ask whether it belongs in the repo or in `~/.config/bash/local.sh`.
