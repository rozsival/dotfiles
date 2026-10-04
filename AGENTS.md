# AGENTS.md

Guidance for AI agents working in this repository.

## What this is

macOS dotfiles for an AI-first workstation (Apple Silicon, macOS 26+). `install.sh` → `bin/dot setup`
automates everything a script can; `bin/dot agent` starts a harness with `setup/PROMPT.md` and the
`workstation-setup` skill for the human-in-the-loop rest; `bin/dot doctor` is the acceptance test for
both. The laptop drives [devbox](https://github.com/rozsival/devbox) (remote agent container) and runs
OMP / Claude Code locally through devbox's launchers.

## Layout

```
install.sh              fresh-Mac entry: CLT, clone, exec bin/dot setup
bin/dot                 the CLI (setup, agent, doctor, link, brew, macos, identities, vault, update)
Brewfile, Brewfile.mas  packages / App Store apps
home/                   symlinked file-by-file into ~ by `dot link`
seed/                   copied into ~ only when absent (tool-owned afterwards)
macos/defaults.sh       macOS defaults; --check is read-only drift detection
vault.list              secret files kept as 1Password Documents (`dot vault`)
setup/PROMPT.md         first message of the guided-setup session
.agents/skills/         workstation-setup skill (.claude/skills/ holds symlinks for Claude Code)
```

## Critical rules

1. **Bash 3.2 for bootstrap code.** `install.sh`, `bin/dot` and `macos/defaults.sh` run on a fresh Mac
   before Homebrew bash exists: no associative arrays, `mapfile`, `${x,,}`, `declare -n`,
   `$EPOCHREALTIME`. Check with `/bin/bash -n`.
2. **`home/.config/bash/env.sh` is sourced by every shell**, including agents' non-interactive ones: no
   output, no subprocesses (no `brew --prefix`, no `$(...)`), no `git config --global` anywhere in shell
   files (in an agent session that writes the agent's gitconfig). Slow init output goes through
   `_dot_cached` in `interactive.sh`. Startup budget: < 400 ms (`dot doctor` measures it).
3. **Ownership boundaries.** Never manage `~/.config/devbox/**` (except restoring `identities.conf` and
   `secrets.env` via `vault.list`), `~/.local/libexec/devbox-agent/**`, `~/.local/bin/devbox-*`,
   `~/.claude/settings.json` (moshi-hook and other tools rewrite its hooks). `~/.omp/agent/config.yml` is a
   seed, never a symlink: `devbox sync omp` rsyncs it and a symlink would arrive dangling.
4. **Identity is rendered, not tracked.** `user.*`, `gpg.*`, `commit/tag.gpgsign` and `includeIf` live in
   the `~/.gitconfig` that `dot identities` renders from `~/.config/devbox/identities.conf` via devbox's
   own library. Never put them in `home/.config/git/config`: `devbox doctor laptop` reads
   `git config --global` without `--includes`.
5. **No secrets in git.** A file holding a credential gets a `vault.list` line, never a `home/` or `seed/`
   entry. No private keys anywhere: SSH and signing go through the 1Password agent.
6. **macOS defaults mirror reality.** Every key in `macos/defaults.sh` must be checkable by `--check`,
   carry the value this Mac actually has (or a stated security override), and work with SIP enabled. Drop
   keys whose feature is gone rather than keeping them "just in case".
7. **Every manual step is a doctor check.** A new thing a person must do on a new Mac gets a check in
   `dot doctor` (with a `hint` naming the fix) and a phase entry in the `workstation-setup` skill.
8. **One app per cask in the Brewfile.** Without a terminal `bin/dot` sets `HOMEBREW_NO_SUDO`, so a cask
   step macOS refuses fails instead of hanging; Homebrew's rollback of a cask that ships two apps would
   delete the first, already adopted app from /Applications. Check a new cask with
   `brew info --cask --json=v2 <name> | jq '[.casks[0].artifacts[] | .app? // empty] | length'`.

## Working in an agent session

Sessions started through the devbox launchers export `GIT_CONFIG_GLOBAL` (the agent gitconfig) and a `gh`
shim, and OMP's guardrails deny unsetting them. To inspect the human config use
`git config --file ~/.gitconfig …` or `git config --file ~/.gitconfig --includes …` from inside a repo,
not `git config --global`.

## Verify

```bash
shellcheck bin/dot install.sh macos/defaults.sh home/.bashrc home/.bash_profile home/.config/bash/*.sh
/bin/bash -n bin/dot && /bin/bash -n install.sh && /bin/bash -n macos/defaults.sh
bin/dot link --dry-run      # what linking would change
bin/dot macos --check       # read-only
bin/dot doctor
```

Risky paths (`dot link`, `dot identities`) can be exercised against a throwaway `HOME=$(mktemp -d)`.
