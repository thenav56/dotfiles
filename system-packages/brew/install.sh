#!/usr/bin/env bash

set -x

if ! type "brew" > /dev/null; then
   echo 'Installing brew first'
   /usr/bin/env bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   eval "$(/opt/homebrew/bin/brew shellenv)"
fi

BREW_CONFIG_LOC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

brew bundle
