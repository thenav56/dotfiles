#!/bin/sh
# From: https://github.com/polybar/polybar-scripts/blob/master/polybar-scripts/dunst-snooze/dunst-snooze.sh

case "$1" in
    --toggle)
        dunstctl set-paused toggle
        polybar-msg action dunst-snooze hook 0
        ;;
    *)
        if [ "$(dunstctl is-paused)" = "true" ]; then
            echo "%{F#D9534F} 󰂛 %{F-}"
        else
            echo "%{F#20C997} 󰂚 %{F-}"
        fi
        ;;
esac
