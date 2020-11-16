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

Follow [this awesome manual](https://getgrav.org/blog/macos-bigsur-apache-multiple-php-versions). Parts with `$PATH` setup can be skipped, everything is set in `.path`.

> ⚠️ **Apache configuration should prefer `php-fpm` over `mod_php`.**

```apacheconf
LoadModule proxy_module lib/httpd/modules/mod_proxy.so
LoadModule proxy_fcgi_module lib/httpd/modules/mod_proxy_fcgi.so

<IfModule proxy_fcgi_module>
    <VirtualHost *:*>
        ProxyPassMatch "^/(.*\.php(/.*)?)$" "fcgi://127.0.0.1:9000/<$serverRoot>/$1"
    </VirtualHost>
    <FilesMatch \.php$>
        SetHandler "proxy:fcgi://127.0.0.1:9000"
    </FilesMatch>
</IfModule>
```

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
