#!/usr/bin/env bash

BASEDIR="$(dirname "${BASH_SOURCE[0]}")"

if ! type "yay" > /dev/null; then
    echo 'Installing yay first'
    sudo pacman -S --needed git base-devel
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    cd /tmp/yay-bin
    yes | makepkg -si
fi

yes | yay --needed -S $(cat $BASEDIR/native.txt)

yay --needed -S --noconfirm $(cat $BASEDIR/aur.txt)
