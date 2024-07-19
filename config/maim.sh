#!/usr/bin/env bash

mkdir -p "/home/$USER/Pictures/screenshots/"
maim --select "/home/$USER/Pictures/screenshots/$(date +%Y-%m-%d.%H:%M:%S).png"
