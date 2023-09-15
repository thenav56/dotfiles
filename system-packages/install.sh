#!/usr/bin/env bash

BASEDIR="$(dirname "${BASH_SOURCE[0]}")"


cd $BASEDIR
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo 'System detected: MacOS'
    # Mac: brew
    $BASEDIR/brew/install.sh
else
    echo 'System detected: Arch'
    # Arch
    $BASEDIR/arch/install.sh
fi

# Install npm first
npm install -g git-split-diffs
