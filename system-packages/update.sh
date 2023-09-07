#!/usr/bin/env bash

set -x

BASEDIR="$(dirname "${BASH_SOURCE[0]}")"

yay -Qqne > $BASEDIR/native-packages.txt
yay -Qqme > $BASEDIR/aur-packages.txt
