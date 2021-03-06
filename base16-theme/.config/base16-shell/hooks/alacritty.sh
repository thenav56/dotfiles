#!/usr/bin/env bash

# Make sure to remove echo ". ~/.base16_theme" from base16-shell/profile_helper.sh
COLORSCHEME_SWITCH_DIR=~/.alacritty-colorscheme/alacritty_colorscheme
COLORSHCEME_DIR=~/.alacritty-theme/colors

python3 $COLORSCHEME_SWITCH_DIR/cli.py -C $COLORSHCEME_DIR -a base16-${BASE16_THEME}.yml

# Send custom command to nevim server (Here `<Esc>,s` is key mapping to reload neovim cofig)
for NVIM_SERVER in $(nvr --serverlist)
do
    nvr --servername $NVIM_SERVER --remote-send '<Esc>,s' &
done

