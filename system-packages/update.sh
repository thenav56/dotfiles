#!/usr/bin/env bash
#
BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


cd $BASEDIR
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo 'System detected: MacOS'
    # Mac
    ./brew/update-info.sh
else
    echo 'System detected: Arch'
    # Arch
    ./arch/update-info.sh
fi
