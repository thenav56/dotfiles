#!/bin/bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

LOCK_AFTER=900
WAKE_UP_SCRIPT=$SCRIPT_DIR/swayidle-output-on.sh

# NOTE: Don't add comment inside here.
swayidle \
    timeout $LOCK_AFTER "pgrep -x swaylock || $1" \
    timeout 10 'if pgrep -x swaylock; then swaymsg "output * dpms off"; fi' \
    resume $WAKE_UP_SCRIPT
