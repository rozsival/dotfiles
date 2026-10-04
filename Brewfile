# Applied by `dot` via `brew bundle --file Brewfile`. App Store apps: Brewfile.mas.
# OMP and Claude Code ship their own installers and are intentionally absent.

# Taps (only where the formula/cask is not in homebrew-core/cask)
tap "azure/kubelogin"
tap "hashicorp/tap"
tap "mongodb/brew"
tap "rjyo/moshi"
tap "steipete/tap"
tap "superhq-ai/tap"

# Shell & core CLI
brew "bash"
brew "bash-completion@2"
brew "coreutils"
brew "findutils"
brew "gnu-sed"
brew "grep"
brew "moreutils"
brew "nano"
brew "mise"
brew "starship"
brew "mas"
brew "wget"
brew "bat"
brew "bottom"
brew "fd"
brew "jq"
brew "ripgrep"
brew "yq"
brew "mosh"
brew "wakeonlan"
brew "mkcert"
brew "gnupg"
# No brew openssh: /usr/bin/ssh (OpenSSH 10.x) already supports `ssh -P tag` / `Match tagged`.
cask "ghostty"
cask "1password"
cask "1password-cli"

# Git & GitHub
brew "git"
brew "git-filter-repo"
brew "git-lfs"
brew "gh"
brew "glab"
brew "lazygit"
brew "worktrunk"
brew "actionlint"
brew "shellcheck"
brew "shfmt"
brew "bashly"

# AI & agents
cask "codex" # Codex CLI via cask; replaces the standalone install in ~/.local/bin
cask "chatgpt"
cask "claude" # desktop app only; Claude Code uses its own installer
cask "codexbar"
brew "herdr" # in homebrew-core; replaces the standalone binary in ~/.local/bin
brew "llmfit" # homebrew-core now ships it, so the alexsjones tap is no longer needed
brew "superhq-ai/tap/shuru"
brew "rjyo/moshi/moshi-hook"

# Languages & runtimes
brew "rustup" # keg-only: run `rustup default stable` once to get cargo/rustc shims
brew "cargo-binstall"
brew "uv" # replaces pipx and the standalone ~/.local/bin install
brew "openjdk"
# Node, Python versions etc. are managed per-project by mise.

# Cloud, Kubernetes & DB clients
brew "azure-cli"
brew "azure/kubelogin/kubelogin"
brew "helm"
brew "k9s"
brew "kubectx"
brew "hashicorp/tap/terraform"
brew "mongosh"
brew "mongodb/brew/mongodb-database-tools"
cask "gcloud-cli" # replaces ~/google-cloud-sdk (formerly the google-cloud-sdk cask)
cask "freelens"
cask "docker-desktop"
cask "insomnia"

# Build toolchain (C/C++, Java, mobile)
brew "llvm"
brew "cmake"
brew "ninja"
brew "ccache"
brew "cpplint"
brew "autoconf"
brew "autoconf-archive"
brew "automake"
brew "libtool"
brew "pkgconf"
brew "maven"
brew "cocoapods"

# Media
brew "ffmpeg"
brew "yt-dlp"
brew "vips"
brew "imagemagick"
brew "ghostscript"
brew "atomicparsley"

# Apps: work
cask "jetbrains-toolbox"
cask "notion"
cask "notion-calendar"
cask "google-chrome"
cask "microsoft-edge"
cask "google-drive"
cask "zoom"
cask "foxglove"

# Apps: communication
cask "signal"
cask "whatsapp"

# Apps: utilities
cask "appcleaner"
cask "rectangle-pro"
cask "tailscale-app" # GUI app; the `tailscale` cask name is an alias for this
cask "openvpn-connect"
cask "winbox"
cask "balenaetcher"
cask "raspberry-pi-imager"
cask "trezor-suite"

# Apps: media & hobby
cask "vlc"
cask "obs"
cask "epic-games"
cask "nvidia-geforce-now"
