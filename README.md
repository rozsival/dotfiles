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

### Setup development environment

Follow https://getgrav.org/blog/macos-catalina-apache-multiple-php-versions. Parts with `$PATH` setup can be skipped, everything is set in `.path`.

Setup Yarn [`version`](https://yarnpkg.com/en/docs/cli/version#toc-git-tags) to publish `npm` packages correctly.
