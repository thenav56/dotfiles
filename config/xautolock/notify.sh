#!/usr/bin/env bash

if pgrep -x i3lock > /dev/null
then
    echo "Lock alreay running. Nothing to do there";
    exit 0
fi

notify-send \
    --urgency=critical \
    --icon preferences-desktop-screensaver \
    --expire-time=5000 \
    "about to lock screen ..." "move or use corners"
