#!/usr/bin/env bash

echo "Updating kitty instances with $BASE16_THEME & Font $KITTY_CUSTOM_FONT"

# Depends on ~/.dotfiles/config/kitty/kitty.conf:listen_on
SOCKETS_PATH='/tmp/kitty.sock'

function update_kitty() {
    echo " - $KITTY_LISTEN_ON"
    echo "font_family $KITTY_CUSTOM_FONT" > $HOME/.config/kitty/base16_hooks.conf

    sleep 0.5
    echo " * Set-colors to all kitty instances"
    kitty @ set-colors -ac $HOME/.dotfiles/base16/kitty/colors/base16-$BASE16_THEME-256.conf

    echo " * Try reloading kitty config using -SIGUSR1"
    # NOTE: This is for reloading kitty config (Basically for changed fonts)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        kill -SIGUSR1 $(ps -A | grep "MacOS/[k]itty" | awk '{print $1}')
    else
        kill -SIGUSR1 $(pidof kitty)
    fi
}


if [ -z "$KITTY_LISTEN_ON" ] ; then
    for KITTY_SOCKET_PATH in $SOCKETS_PATH-*; do
        export KITTY_LISTEN_ON="unix:$KITTY_SOCKET_PATH"
        update_kitty
    done
else
    # Normal run with kitty
    update_kitty
fi
