!#/usr/bin/env bash


pkill polybar


# Primary
for m in $(polybar --list-monitors | grep primary | cut -d":" -f1); do
    MONITOR=$m polybar -r &
done

# Secondary
for m in $(polybar --list-monitors | grep -v primary | cut -d":" -f1); do
    MONITOR=$m polybar -r -c ~/.dotfiles/config/polybar/polybar-secondary.ini &
done

# Tray stops working, reloading fix it for now
polybar-msg cmd reload
