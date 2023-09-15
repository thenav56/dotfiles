#!/usr/bin/env bash

echo 'Updating kitty instances'
exec bash -c 'kitty @ set-colors -ac $HOME/.dotfiles/base16/kitty/colors/base16-$BASE16_THEME.conf'
exec bash -c 'kitty @ env BASE16_THEME=$BASE16_THEME'
