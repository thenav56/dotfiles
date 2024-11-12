#!/usr/bin/env bash

echo "Updating alacritty theme $BASE16_THEME"
cat "$HOME/.dotfiles/base16/alacritty/colors/base16-$BASE16_THEME-256.toml" > ~/.config/alacritty/base16-theme.toml
