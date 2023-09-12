#!/usr/bin/env bash

echo 'Updating neovim instances'
for servername in $(nvr --serverlist 2>/dev/null):
do
    # Only for parent node
    if [[ $servername == *.0 ]]; then
        echo ' -' $servername
        nvr -s \
            --servername $servername \
            --nostart \
            --remote-send \
            "<ESC>:colorscheme base16-$BASE16_THEME<ENTER>"
    fi
done
