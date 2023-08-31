#!/usr/bin/env bash

echo 'Updating kitty instances'
kitty @ set-colors -ac $HOME/.dotfiles/base16/kitty/colors/base16-$BASE16_THEME.conf
kitty @ env BASE16_THEME=$BASE16_THEME
