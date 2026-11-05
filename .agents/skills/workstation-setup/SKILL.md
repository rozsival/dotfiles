---
name: workstation-setup
description: Guides a person through the parts of setting up this Mac that a script cannot do - updating macOS, 1Password with its SSH agent and AutoFill, restoring secret files from 1Password (`dot vault pull`), devbox's laptop agent tooling, rendering git/ssh identity config (`dot identities`), GitHub login, Tailscale and the devbox connection (herdr, `devbox doctor laptop`), agent logins, Moshi pairing, App Store apps, JetBrains IDEs, cloud CLI logins, first app launches - driven by `bin/dot doctor` as the acceptance test, in English or Czech. Use when setting up a new or reinstalled Mac, when `dot doctor` fails, or when asked what is still missing on this machine.
---

# Workstation setup

`bin/dot doctor` is the acceptance test: every ✗ names a gap and its `→` line the fix. Run it, take
failures in the phase order below (later phases depend on earlier ones), re-run the specific check
after each step, and finish when doctor prints `all checks passed`. Warnings (`!`) are judgement
calls - mention them, fix them if the person agrees. When doctor ends with `fix(es) dot can run itself`,
start there: the person runs `bin/dot doctor --fix` in their own terminal (it needs sudo and refuses an
agent shell), then take what remains.

`install.sh` already installed Xcode CLT, Homebrew and Homebrew bash (`bin/dot` needs it), and `bin/dot
setup` ran: Xcode license (if Xcode was installed), `Brewfile`, Homebrew bash as login shell, `dot link`, mise Node, rustup, Terraform and OpenTofu via tenv, the devbox clone
(HTTPS) and its OMP preset in `~/.omp/agent/config.yml`, OMP, Claude Code,
agent-browser CLI, global skills, moshi-hook service + hooks, Touch ID for sudo, macOS defaults (including key
repeat and the Czech + ABC keyboard layouts). Re-run a
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

## Language

Speak the language of this Mac's interface: the first entry of `defaults read -g AppleLanguages` (`cs-…`
means Czech, informal "ty"), unless the person writes in another language. Every click path names the
labels exactly as the screen shows them, never a translation of your own. System Settings labels for
the paths below, as macOS 27 shows them (`dot doctor` hints are in English; give the person the
matching Czech path):

| English                                              | Czech                                                                         |
| ---------------------------------------------------- | ----------------------------------------------------------------------------- |
| System Settings                                      | Nastavení systému                                                             |
| General → Software Update                            | Obecné → Aktualizace softwaru                                                 |
| General → AutoFill & Passwords                       | Obecné → Automatické vyplňování a hesla                                       |
| … AutoFill Passwords and Passkeys                    | … Automatické vyplňování hesel a přístupových klíčů                           |
| … AutoFill from                                      | … Zdroje                                                                      |
| … Verification Codes → Set Up Codes In               | … Ověřovací kódy → Nastavovat kódy v aplikaci                                 |
| General → Login Items & Extensions → Open at Login   | Obecné → Aktivace položek a rozšíření při přihlášení → Otevřít při přihlášení |
| Privacy & Security → App Management                  | Soukromí a zabezpečení → Správa aplikací                                      |
| Privacy & Security → Accessibility                   | Soukromí a zabezpečení → Zpřístupnění                                         |
| Privacy & Security → Microphone                      | Soukromí a zabezpečení → Mikrofon                                             |
| Privacy & Security → Screen & System Audio Recording | Soukromí a zabezpečení → Záznam obrazovky a systémového zvuku                 |
| Privacy & Security → FileVault                       | Soukromí a zabezpečení → FileVault                                            |
| Keyboard → Text Input → Input Sources → Edit…        | Klávesnice → Zadání textu → Vstupní zdroje → Upravit…                         |
| Keyboard → Key repeat rate, Delay until repeat       | Klávesnice → Rychlost opakování kláves, Prodleva opakování                    |
| App Store app: Store → Sign In                       | App Store: Obchod → Přihlásit se                                              |

A System Settings label not in this table: describe where it is (pane, section, position) and ask the
person to read it out, then use their wording. Third-party apps (1Password, Docker Desktop, JetBrains
Toolbox…) show their own labels, often English on a Czech Mac: quote those as they appear.

## Phase 0 - macOS up to date

README's quick start makes this step 0, before `install.sh`, and `install.sh` refuses anything older
than macOS 27. If doctor still warns `software updates pending` (what Software Update found at its last
scan), the person installs them first: System Settings → General → Software Update, restart, then
`bin/dot agent` again. After `dot setup` the person logs out and back in once: key repeat and keyboard
shortcuts take effect only at login; if holding a key still repeats slowly, they have not.
Verify: the macOS line in doctor's System section, no `software updates pending`.

## Phase 1 - 1Password

Everything after this depends on it. The person:

1. Opens 1Password, signs in to every account (personal `my.1password.com`, work `apitree.1password.eu` and
   `sitefellows.1password.eu`).
2. Settings → Security: Touch ID on.
3. Settings → Developer: **Use the SSH agent** on, **Integrate with 1Password CLI** on.
4. System Settings → General → AutoFill & Passwords: **AutoFill Passwords and Passkeys** on, under
   **AutoFill from** 1Password on, and **Set Up Codes In** (Verification Codes) set to 1Password. Czech
   labels in the table above. Verify: doctor's `1Password fills passwords and passkeys` and
   `1Password sets up verification codes`.

Which vaults the agent serves is `~/.config/1Password/ssh/agent.toml`, tracked (`home/`, symlinked by
`dot link`): a key in a vault or account it doesn't list is invisible to ssh. Verify: doctor's
`1Password SSH agent` and `op CLI knows my.1password.com`; `SSH_AUTH_SOCK=… ssh-add -l` lists the auth and
signing key of each identity plus `Devbox Laptop`.

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
cd ~/projects/rozsival/devbox                       # `dot setup` cloned it over HTTPS
./bin/devbox install                                # `devbox` on the PATH (~/.local/bin/devbox), bash completion
./bin/devbox agent install                          # launchers, gh shim, credential helper, devbox-identities
echo 'DEVBOX_HOST=panther-minor' >.push.env         # workstation alias for `devbox deploy` and `doctor laptop`
```

`agent install` installs the `omp`/`claude` launchers, `gh` shim, credential helper, `devbox-identities`,
agent gitconfigs. The PATH line it prints is already in `~/.config/bash/env.sh` - nothing to add; open a
new shell. Its other printed steps (identities.conf, tokens, App credentials) were covered by phase 2.
`.push.env` is gitignored, so a new Mac never has it; without it `devbox deploy` needs the host as an
argument and `devbox doctor laptop` silently skips its `Host panther-minor` check.
Verify: doctor's `omp -> devbox launcher`, `claude -> devbox launcher`; `command -v devbox` prints
`~/.local/bin/devbox`.

## Phase 4 - git and ssh identity

```bash
bin/dot identities
```

Renders from `~/.config/devbox/identities.conf`, with devbox's own renderer: `~/.gitconfig` (default
identity, op-ssh-sign signing, `includeIf` per tree and per GitHub org), `~/.config/git/identities/*`,
`~/.ssh/config.d/identities` (GitHub `Host`/`Match … tagged` blocks), `~/.ssh/allowed_signers`, and the
`id_<slug>.pub`/`signing_<slug>.pub` selectors. Shared git settings stay in `~/.config/git/config`
(tracked); never put identity there. `~/.ssh/config` itself is tracked (`home/.ssh/config`, symlinked): it
holds `Host *` with the 1Password socket, `panther-minor`/`pi-zero` (`id_personal.pub`) and `devbox`
(`devbox.pub`), and `Include`s the rendered GitHub blocks. Editing it edits this repo.

`~/.ssh/devbox.pub` is not in the registry: take it from the agent -
`SSH_AUTH_SOCK=… ssh-add -L | grep 'Devbox Laptop' > ~/.ssh/devbox.pub` (the comment is the item title;
if it differs, list with `ssh-add -L` and ask which line).

Verify: doctor's identity lines; `git -C ~/projects/rozsival/dotfiles config user.email`.

## Phase 5 - GitHub

1. The person runs `gh auth login --hostname github.com --git-protocol ssh --web`.
2. SSH: `ssh -T git@github.com` (personal), `ssh -P apitree -T git@github.com` and
   `ssh -P sitefellows -T git@github.com` each answer
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
   and connections. Its hints assume hand-written config; here the owners differ. An `id_*`/`signing_*`
   `.pub`, GitHub `Host`/`Match`, `~/.gitconfig`, `includeIf` or `allowed_signers` failure: fix
   `~/.config/devbox/identities.conf` if needed and re-run `bin/dot identities`, never hand-edit the
   rendered files. A `Host devbox`/`Host panther-minor` failure: `home/.ssh/config` in this repo. Launchers,
   agent gitconfigs, tokens, App credentials: that repo's `devbox-laptop` skill.

## Phase 7 - agents and phone

- The harness that runs this session is already signed in: `dot agent` needs that first (README quick
  start). The other one: Claude Code - the person runs `claude` and `/login`; OMP - `omp login anthropic`
  (Claude Pro/Max). Codex: `codex login`. Verify: doctor's `omp signed in to Anthropic`,
  `claude signed in (/login)` and `codex signed in`.
- Moshi for Mac has no cask: the person downloads it from https://getmoshi.app. Pairing: Moshi iPhone app →
  Settings → Integrations (Hooks in older versions) → token, then the person runs `moshi-hook pair --token <token>`. Verify:
  `moshi-hook status` shows `status: paired`; `moshi-hook doctor`. If pairing's first-run prompt turned
  server discovery back to every port, doctor flags `moshi-hook scan-ports`: `dot scan-ports` restores it
  (probing every port answers login callbacks such as `gcloud auth login` before the tool does).
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
- App Store, never skipped (doctor fails on `App Store apps missing`): the person opens the App Store app
  and signs in with Store → Sign In (`mas` cannot sign in), then runs `bin/dot brew --mas` in their own
  Ghostty tab. Tell them first that Xcode, Final Cut Pro and Logic Pro are large and take a while. It accepts
  the Xcode license once Xcode is in (sudo): while that is pending every `brew` command fails, and doctor's
  "Xcode license" check offers `dot doctor --fix`.
- No cask, manual download: Moshi (above), Amphetamine Enhancer (from within Amphetamine).
- JetBrains Toolbox: sign in, enable Settings → Tools → Shell scripts → `~/bin`, install the IDEs in
  use (CLion, DataGrip, PyCharm, Rider, RustRover, WebStorm), sign in to each for Settings Sync.
- Spokenly: the person signs in within the app, so its settings sync restores modes, word replacements
  and model settings, then grants Microphone and Accessibility when asked. Doctor cannot see the login;
  the person confirms modes and word replacements are back.
- First runs that need the person: Docker Desktop (accept terms; Settings → Advanced → untick "Allow the
  default Docker socket to be used", else it asks for an admin password at every boot; it may prepend a PATH
  block to the linked `~/.bash_profile`, which `env.sh` already covers: delete it from `home/.bash_profile`),
  Rectangle Pro (license, Accessibility permission), Google Drive, Slack, Notion, Signal, WhatsApp.
- Login items worth restoring: Rectangle Pro, Pure Paste, Google Drive, Notion Calendar, duet, CodexBar,
  Spokenly.

## Phase 9 - cloud and package registries (only what the person uses)

`gcloud auth login && gcloud auth application-default login`, `az login`, `kubelogin` /
`az aks get-credentials`, `glab auth login`. `npm whoami` checks the restored `~/.npmrc`.

## Phase 10 - finish

`bin/dot doctor` passes. Remaining warnings are listed for the person with a recommendation. If `git -C
~/projects/rozsival/dotfiles status` shows changes under `home/`, an installer edited a linked file:
show the diff and ask whether it belongs in the repo or in `~/.config/bash/local.sh`.

End with a short summary in the person's language: what was set up, what is still open (warnings,
skipped phases), and the apps they have to open themselves for the first time. Find those with

```bash
for app in /Applications/*.app /Applications/*/*.app; do
  [ "$(mdls -raw -name kMDItemLastUsedDate "$app" 2>/dev/null)" = '(null)' ] && echo "${app#/Applications/}"
done
```

(never launched since install; leave out uninstallers and apps macOS ships, such as Safari). Spotlight may
still be indexing a fresh Mac and report an opened app as never used: check the list against phase 8's
first runs and ask when unsure. Give each app its first-run action from phase 8 or the app's own prompt:
sign-in, license, permission, login item.
