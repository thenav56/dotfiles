#!/usr/bin/env bash

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! type "yay" > /dev/null; then
    echo 'Installing yay first'
    sudo pacman -S --needed git base-devel
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    cd /tmp/yay-bin
    yes | makepkg -si
fi

# TO UPDATE: yay -Qqe > ~/.dotfiles/arch-packages.txt
yes | yay --needed -S $(cat $BASEDIR/arch-packages.txt)
