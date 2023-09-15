#!/usr/bin/env bash

set -x

BREW_CONFIG_LOC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

brew leaves > $BREW_CONFIG_LOC/formulas.txt
brew list --casks > $BREW_CONFIG_LOC/casks.txt

echo '## Latest formulas'
cat $BREW_CONFIG_LOC/formulas.txt

echo '## Latest casks'
cat $BREW_CONFIG_LOC/casks.txt
