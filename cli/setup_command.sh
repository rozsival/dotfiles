## install.sh has installed Xcode CLT, Homebrew and Homebrew bash: bin/dot needs that bash.
brew_env || die "Homebrew missing in $HOMEBREW_PREFIX: run install.sh"
sudo -v
step 'Packages (Brewfile)'
brew bundle --file "$DOTFILES/Brewfile" || warn 'some Brewfile entries failed; fix them and re-run `dot brew`'
step 'Login shell'
setup_shell
step Dotfiles
link_home
shell_env
step Runtimes
setup_runtimes
step 'AI agents'
setup_agents
step 'Touch ID for sudo'
setup_touchid
step 'macOS defaults'
"$DOTFILES/macos/defaults.sh" || warn 'some defaults failed to apply; see above'

step 'Automated part done'
cat <<EOF
    The rest needs you: 1Password, SSH keys on GitHub, Tailscale, logins, App Store.
    Open Ghostty (it starts the new login shell) and run:

      cd $(tilde "$DOTFILES") && bin/dot agent

    An agent session walks you through it, driven by \`dot doctor\`.
EOF
