#!/usr/bin/env bash

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo `pwd $BASEDIR`

if ! type "yay" > /dev/null; then
    echo 'Installing yay first'
    sudo pacman -S --needed git base-devel
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    cd /tmp/yay-bin
    yes | makepkg -si
fi

sudo pacman --noconfirm --needed -S - < $BASEDIR/native.txt

yay --needed -S --noconfirm - < $BASEDIR/aur.txt
:wa
