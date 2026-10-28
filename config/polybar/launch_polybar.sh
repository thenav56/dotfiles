#!/usr/bin/env bash


pkill polybar

# Sync bar colors with the active base16 theme (polybar-base.ini includes the output)
~/.dotfiles/config/polybar/scripts/gen-colors.sh

# CPU temp sensor: hwmonN index changes across boots, so resolve by driver name
for h in /sys/class/hwmon/hwmon*; do
    case "$(cat "$h/name" 2>/dev/null)" in
        coretemp|k10temp|zenpower) export CPU_TEMP_PATH="$h/temp1_input"; break ;;
    esac
done

NUM_OF_MONITOR=$(polybar --list-monitors | wc -l)

# Single Monitor
if [[ "$NUM_OF_MONITOR" == 1 ]] ; then
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
