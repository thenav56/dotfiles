#!/usr/bin/env bash

if ! [[ -z "$VIM_ACTIVE_THEME" ]]; then
    ACTIVE_THEME=$VIM_ACTIVE_THEME
fi

echo "Updating neovim instances with $ACTIVE_THEME"
for servername in $(nvr --serverlist 2>/dev/null):
do
    # Only for parent node
    if [[ $servername == *.0 ]]; then
        echo ' -' $servername
        nvr -s \
            --servername $servername \
            --nostart \
            --remote-send \
            "<ESC>:colorscheme $ACTIVE_THEME<ENTER>"
    fi
done

echo " * Update $VIM_ACTIVE_THEME_FILE with $ACTIVE_THEME"
echo $ACTIVE_THEME > $VIM_ACTIVE_THEME_FILE
