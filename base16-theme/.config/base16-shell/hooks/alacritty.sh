#!/usr/bin/env bash

# Make sure to remove echo ". ~/.base16_theme" from base16-shell/profile_helper.sh
COLORSCHEME_SWITCH_DIR=~/.alacritty-colorscheme/alacritty_colorscheme
COLORSHCEME_DIR=~/.alacritty-theme/colors

python3 $COLORSCHEME_SWITCH_DIR/cli.py -C $COLORSHCEME_DIR -a base16-${BASE16_THEME}.yml
