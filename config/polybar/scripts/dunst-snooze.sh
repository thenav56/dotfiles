#!/bin/sh
# From: https://github.com/polybar/polybar-scripts/blob/master/polybar-scripts/dunst-snooze/dunst-snooze.sh

# base16 colors from gen-colors.sh (base08 red, base0B green)
[ -f "$HOME/.config/polybar/colors.sh" ] && . "$HOME/.config/polybar/colors.sh"

case "$1" in
    --toggle)
        dunstctl set-paused toggle
        polybar-msg action dunst-snooze hook 0
        ;;
    *)
        if [ "$(dunstctl is-paused)" = "true" ]; then
            echo "%{F${POLYBAR_base08:-#D9534F}}󰂛%{F-}"
        else
            echo "%{F${POLYBAR_base0B:-#20C997}}󰂚%{F-}"
        fi
        ;;
esac
