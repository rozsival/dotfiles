#!/usr/bin/env bash

# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
source ~/.bash_profile

# Install node.js LTS
nvm install --lts

# Install corepack
npm install -g corepack@latest
