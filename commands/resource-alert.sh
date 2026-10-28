#!/usr/bin/env bash
# Critical (red, sticky) dunst notification when RAM / disk usage is high.
# Fires once on crossing threshold; replaced by a short "recovered" note when usage
# drops HYSTERESIS% below threshold. Started from i3 (exec_always) -- single instance.
#
# Env overrides: MEM_THRESHOLD, DISK_THRESHOLD, HYSTERESIS, INTERVAL

MEM_THRESHOLD=${MEM_THRESHOLD:-90}
DISK_THRESHOLD=${DISK_THRESHOLD:-90}
HYSTERESIS=${HYSTERESIS:-5}
INTERVAL=${INTERVAL:-30}

# Single instance: kill previous run on i3 reload
LOCK="${XDG_RUNTIME_DIR:-/tmp}/resource-alert.pid"
if [[ -f $LOCK ]] && kill -0 "$(cat "$LOCK")" 2>/dev/null; then
    kill "$(cat "$LOCK")"
fi
echo $$ >"$LOCK"

# Alert state survives restarts (i3 reload) so it doesn't re-notify
STATE="${XDG_RUNTIME_DIR:-/tmp}/resource-alert"
mkdir -p "$STATE"

notify() { # key urgency summary body
    notify-send -u "$2" -a resource-alert -h "string:x-dunst-stack-tag:resource-$1" "$3" "$4"
}

check() { # key label pct threshold
    local key=$1 label=$2 pct=$3 threshold=$4
    local flag="$STATE/${key//\//_}"
    if ((pct >= threshold)); then
        if [[ ! -e $flag ]]; then
            notify "$key" critical "󰀦 $label usage high" "$label at ${pct}% (>= ${threshold}%)"
            touch "$flag"
        fi
    elif [[ -e $flag ]] && ((pct < threshold - HYSTERESIS)); then
        notify "$key" low "$label usage OK" "$label back to ${pct}%"
        rm -f "$flag"
    fi
}

while true; do
    mem_pct=$(awk '/^MemTotal/ {t=$2} /^MemAvailable/ {a=$2} END {printf "%d", (t-a)*100/t}' /proc/meminfo)
    check mem "RAM" "$mem_pct" "$MEM_THRESHOLD"

    # One check per device (skip bind mounts of the same source)
    declare -A seen=()
    while read -r src pct target; do
        [[ -n ${seen[$src]} ]] && continue
        seen[$src]=1
        check "disk:$src" "Disk $target" "${pct%\%}" "$DISK_THRESHOLD"
    done < <(df --output=source,pcent,target -x tmpfs -x devtmpfs -x efivarfs -x squashfs -x overlay 2>/dev/null | tail -n +2)
    unset seen

    sleep "$INTERVAL"
done
