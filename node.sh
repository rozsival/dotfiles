#!/usr/bin/env bash

# Backup .bash_rc as pnpm installation modifies it
cp ~/.bashrc ~/.bashrc.bak

# Install pnpm
curl -fsSL https://get.pnpm.io/install.sh | sh -
mv -f ~/.bashrc.bak ~/.bashrc
source ~/.bashrc

# Install node.js LTS
pnpm env use --global lts
