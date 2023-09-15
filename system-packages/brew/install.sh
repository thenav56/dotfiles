#!/usr/bin/env bash

set -x

if ! type "brew" > /dev/null; then
   echo 'Installing brew first'
   /usr/bin/env bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

BREW_CONFIG_LOC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

brew tap homebrew/cask-fonts
brew install --formula `cat $BREW_CONFIG_LOC/formulas.txt`
brew install --cask `cat $BREW_CONFIG_LOC/casks.txt`
