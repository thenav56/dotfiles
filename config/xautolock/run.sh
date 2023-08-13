#!/usr/bin/env bash

set -x

# Disable for headless session
if ! [[ "$DISPLAY" == :0 ]]; then
    echo "Only run using DISPLAY:0";
    exit 0
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

NOTIFICATION_CMD=$SCRIPT_DIR/notify.sh
LOCK_CMD='betterlockscreen -l dim'

# Start xautolock
xautolock \
    -time 20 \
    -locker "$LOCK_CMD" \
    -notify 60 \
    -notifier "$NOTIFICATION_CMD" \
    -detectsleep \
    -corners '00--'
