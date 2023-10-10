#!/usr/bin/env bash


pkill polybar

NUM_OF_MONITOR=$(polybar --list-monitors | wc -l)

# Single Monitor
if [[ "$NUM_OF_MONITOR" == 0 ]] ; then
    MONITOR=$(polybar --list-monitors | cut -d":" -f1) polybar -r &
# Multiple Monitors
else
    # Primary
    MONITOR=$(polybar --list-monitors | grep primary | cut -d":" -f1) polybar -r &

    # Secondaries
    for m in $(polybar --list-monitors | grep -v primary | cut -d":" -f1); do
        MONITOR=$m polybar -r -c ~/.dotfiles/config/polybar/polybar-secondary.ini &
    done
fi

# Tray stops working, reloading fix it for now
polybar-msg cmd reload
