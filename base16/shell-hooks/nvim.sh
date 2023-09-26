#!/usr/bin/env bash

if ! [[ -z "$VIM_BASE16_THEME" ]]; then
    BASE16_THEME=$VIM_BASE16_THEME
fi

echo "Updating neovim instances with $BASE16_THEME"
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

echo " * Update $BASE16_THEME_VIM_FILE with $BASE16_THEME"
echo $BASE16_THEME > $BASE16_THEME_VIM_FILE
