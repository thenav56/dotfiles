#!/bin/bash

set -euo pipefail

echo "Killing old ssh-agents"

# Configure the max age here (e.g., 1h, 30m, 45s, 2d)
MAX_AGE_INPUT="${1:-4h}"

# Convert time string to seconds
convert_to_seconds() {
    local input="$1"
    local number unit

    if [[ "$input" =~ ^([0-9]+)([smhd])$ ]]; then
        number="${BASH_REMATCH[1]}"
        unit="${BASH_REMATCH[2]}"
        case "$unit" in
            s) echo "$((number))" ;;
            m) echo "$((number * 60))" ;;
            h) echo "$((number * 3600))" ;;
            d) echo "$((number * 86400))" ;;
            *) echo "Unknown time unit: $unit" >&2; exit 1 ;;
        esac
    else
        echo "Invalid time format: $input" >&2
        exit 1
    fi
}

MAX_AGE_SECONDS=$(convert_to_seconds "$MAX_AGE_INPUT")

echo "Using MAX_AGE_SECONDS=$MAX_AGE_SECONDS from user input $MAX_AGE_INPUT"


# Collect candidate PIDs
declare -a pids_to_kill=()
declare -A pid_ages

for pid in $(pgrep ssh-agent); do
    if [[ -e /proc/$pid ]]; then
        start_time=$(stat -c %Y /proc/$pid)
        now=$(date +%s)
        age=$((now - start_time))

        if (( age > MAX_AGE_SECONDS )); then
            pids_to_kill+=("$pid")
            pid_ages["$pid"]="$age"
        fi
    fi
done

if [[ ${#pids_to_kill[@]} -eq 0 ]]; then
    echo "No old ssh-agent processes found."
    exit 0
fi

echo "The following ssh-agent processes are older than $MAX_AGE_INPUT:"
for pid in "${pids_to_kill[@]}"; do
    age="${pid_ages[$pid]}"
    echo " - PID $pid (age: $((age / 3600))h $(((age % 3600) / 60))m)"
done

read -rp "Do you want to kill these processes? [y/N] " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
    for pid in "${pids_to_kill[@]}"; do
        echo "Killing ssh-agent PID $pid"
        kill -9 "$pid"
    done
else
    echo "Aborted. No processes were killed."
fi
