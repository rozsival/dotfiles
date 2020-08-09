# Vít’s dotfiles

Mac OS X dotfiles with sensible development setup.

## Installation

### Download

```bash
cd; curl -#L https://github.com/rozsival/dotfiles/tarball/master | tar -xzv --strip-components 1 --exclude={README.md,bootstrap.sh,.osx,LICENSE-MIT.txt}
```

Then install [Spectacle](https://www.spectacleapp.com/).

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

### Install `brew`

```bash
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
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

### Others

Setup _Brew-installed_ Ruby by adding following to `.bash_profile`:

```
# Ruby
export PATH="/usr/local/opt/ruby/bin:$PATH"
export GEM_HOME="$HOME/.gem"
```
