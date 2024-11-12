#!/bin/sh

# Get active theme
BAT_ACTIVE_THEME=$(command cat $BAT_THEME_VALUE_FILE)
sh -c "col -bx | command bat --theme $BAT_ACTIVE_THEME -l man -p"
