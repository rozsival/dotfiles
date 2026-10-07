---
name: dot
description: Operates the `dot` CLI that manages this Mac from the rozsival/dotfiles repo - checking machine state (`dot doctor`, `--check` modes), linking dotfiles, Homebrew packages, macOS defaults, git/SSH identity rendering, 1Password-backed secret files (`dot vault`), syncing and upgrading - and knows which runs an agent may start itself and which the person must run in their own terminal. Use when asked to check, sync, update or change this workstation's setup, add a package/dotfile/macOS setting/secret file, or change the `dot` command itself. A new or reinstalled Mac goes to the `workstation-setup` skill instead.
---

# dot

`dot` is on the PATH as `~/.local/bin/dot`, a symlink into the dotfiles repo (`bin/dot`). The repo root is
`"$(dirname "$(dirname "$(readlink -f ~/.local/bin/dot)")")"`, normally `~/projects/rozsival/dotfiles`.
`dot --version` prints the commit the checkout is at.

`dot <command> --help` is the source of truth for options, arguments and examples; read it rather than
guessing a flag. Environment: `DOT_OP_ACCOUNT` (default `my.1password.com`), `DOT_OP_VAULT` (default
`Workstation`), `DEVBOX_DIR` (default `~/projects/rozsival/devbox`).

## Output

`==> Section` headings, then one line per item: `✓` ok, `!` warning (judgement call: report it), `✗`
failure, `→` the command or click path that fixes the line above. `dot: <message>` on stderr with exit 1
is a hard stop (missing prerequisite); its message names the fix. Colours only on a terminal.

## Who runs what

An agent shell has no terminal. `dot` then sets `HOMEBREW_NO_SUDO`, so a cask step that needs sudo fails,
and dot's own `sudo` calls wait on a Touch ID prompt nobody sees. Commands that can reach sudo are the
person's: hand them the exact command, wait, then verify with the read-only form.

| Command                       | Changes                                                                                                                                               | Who                                   |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------- |
| `dot doctor`                  | nothing (fetches origin); exit 1 while any `✗`                                                                                                        | agent                                 |
| `dot link --dry-run`          | nothing                                                                                                                                               | agent                                 |
| `dot link`                    | symlinks `home/` into `~`, copies absent `seed/` files, moves replaced files to `~/.dotfiles-backup/<time>/`, removes links whose source left `home/` | agent, after showing the dry run      |
| `dot brew --check`            | nothing; lists what `Brewfile`/`Brewfile.mas` lack                                                                                                    | agent                                 |
| `dot brew --cleanup`          | nothing; lists installed but undeclared packages                                                                                                      | agent                                 |
| `dot brew` / `dot brew --mas` | installs (casks may need sudo; `--mas` needs the App Store app signed in)                                                                             | person                                |
| `dot macos --check`           | nothing; prints drift                                                                                                                                 | agent                                 |
| `dot macos`                   | writes defaults, sudo for system ones, restarts affected apps                                                                                         | person                                |
| `dot identities --check`      | nothing; exit 1 if a rendered file is missing or stale                                                                                                | agent                                 |
| `dot identities`              | rewrites `~/.gitconfig`, `~/.config/git/identities/*`, `~/.ssh/config.d/identities`, `~/.ssh/allowed_signers`, `id_*`/`signing_*.pub`                 | agent                                 |
| `dot vault [status]`          | nothing; per title: in 1Password, on disk, both, neither                                                                                              | agent (the person approves 1Password) |
| `dot vault pull [title…]`     | writes files missing on disk; `--force` overwrites existing ones                                                                                      | agent; ask before `--force`           |
| `dot vault push [title…]`     | overwrites the 1Password Documents                                                                                                                    | agent, only after the person agrees   |
| `dot sync`                    | `git pull --ff-only`, then `link`, `brew`, `macos --check`                                                                                            | person (Homebrew step)                |
| `dot update`                  | upgrades Homebrew, mise, OMP, Claude Code, skills, moshi-hook; a failed step doesn't stop the rest, exits 1 at the end                                | person                                |
| `dot setup`                   | everything automatable, asks for sudo up front                                                                                                        | person                                |
| `dot agent [omp\|claude]`     | `exec`s an interactive harness                                                                                                                        | person; never from inside an agent    |

## Rules

- Never read secret contents: no `cat`, `op read`, `op item get --reveal` on `vault.list` paths
  (`secrets.env`, `app.pem`, `.npmrc`, `models.yml`, `.env`). Existence and mode only: `dot vault status`,
  `ls -l`. `identities.conf` and `.pub` files are not secret.
- Files under `home/` are live: `~/.bashrc` is a symlink, so editing it edits the repo. Machine-only shell
  lines go in `~/.config/bash/local.sh` (untracked).
- Never hand-edit rendered identity files: change `~/.config/devbox/identities.conf`, then `dot identities`.
- `dot sync` refuses uncommitted changes in the repo; never stash or reset them to get past it - show
  `git status` and let the person decide.
- In a devbox launcher session `git config --global` is the agent's config; read the person's with
  `git config --file ~/.gitconfig`.

## Recipes

Paths are relative to the repo root.

| Goal                            | Steps                                                                                                                                                                          |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| What is wrong with this Mac?    | `dot doctor`; fix each `✗` via its `→` line, re-run the specific check (`--check` forms) after each fix                                                                        |
| CLI or app                      | A line in `Brewfile` (App Store: `Brewfile.mas`; one app per cask; third-party taps fully qualified with `trusted: true`), `dot brew --check`, then the person runs `dot brew` |
| Dotfile                         | File at `home/<path relative to ~>`, `dot link --dry-run`, `dot link`                                                                                                          |
| File a tool rewrites itself     | `seed/<path>` instead of `home/`: copied once, never updated                                                                                                                   |
| macOS setting                   | A `pref` line in `macos/defaults.sh` with this Mac's current value, `dot macos --check`, the person runs `dot macos`                                                           |
| Secret file                     | A `vault.list` line (title, path, mode), then `dot vault push <title>` once the person agrees                                                                                  |
| Identity change                 | Edit `~/.config/devbox/identities.conf`, `dot identities`, `devbox agent install`, `devbox sync identities`, `dot vault push devbox/identities.conf` once the person agrees    |
| Pick up another Mac's changes   | Commit and push here first; the person runs `dot sync` there                                                                                                                   |
| Defaults drift after `dot sync` | `dot macos --check` shows it; either update `macos/defaults.sh` to the new value or the person runs `dot macos`                                                                |
| Upgrade everything              | The person runs `dot update`                                                                                                                                                   |

Commit repo changes with Conventional Commits (`feat:`, `fix(scope):`, `docs:`); `dot doctor` warns while the repo is
ahead of origin.

## Changing `dot` itself

`bin/dot` is generated by bashly; never edit or format it. A command's flags, args, help, examples and
completions live in `cli/bashly.yml`, its body in `cli/<command>_command.sh`, shared code in `cli/lib/`.
Then `make build` and `make check`, and commit `cli/` and `bin/dot` together. Read a flag with an inner
dash as `${args['--dry-run']}` (quoted). Fixed value sets get `allowed:`, open ones `completions:`. A new
or changed command also updates the table above and `README.md`'s command table. The repo's `AGENTS.md`
has the full rules.
