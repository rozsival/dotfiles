# Vít’s dotfiles

MacOS dotfiles with sensible web development setup.

## Installation

### Download

```bash
cd; curl -#L https://github.com/rozsival/dotfiles/tarball/master | tar -xzv --strip-components 1 --exclude={README.md,bootstrap.sh,.osx,LICENSE-MIT.txt}
```

### Disable `csrutil`

When setting up a new Mac (or clean install) reboot in Recovery Mode, open Terminal and run:

```bash
csrutil disable
```

Reboot back to OS.

### Sensible Mac OS defaults

```bash
source .macos
```

### Enable `csrutil` again

Reboot in Recovery Mode and run this in Terminal:

```bash
csrutil enable
```

Reboot back to OS.

### Install build tools

```bash
xcode-select --install
```

### Install `brew`

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
source brew.sh
```

## Setup development environment

### PHP

Follow https://getgrav.org/blog/macos-catalina-apache-multiple-php-versions. **Parts with `$PATH` setup can be skipped, everything is set in `.path`.**

### Node

Install [nvm](https://github.com/nvm-sh/nvm).

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v<$version>/install.sh | bash
```

Install [yarn](https://yarnpkg.com).

```bash
npm install -g yarn
```

Setup Yarn [`version`](https://yarnpkg.com/en/docs/cli/version#toc-git-tags) to publish `npm` packages correctly.
