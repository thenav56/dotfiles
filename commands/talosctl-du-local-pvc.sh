#!/bin/bash -e

NODE_NAME=${1?"Provide NODE_NAME"}
PVC_PATH=${PVC_PATH:-/var/local-path-provisioner/}

talosctl du -n "$NODE_NAME" -H "$PVC_PATH" \
    | awk '{$1=""; print $0}' \
    | awk 'NR == 1 {print} NR > 1 {$1=$1$2; $2=""; print}' \
    | awk '{$1=$1; print}' \
    | awk 'NR == 1 {print} NR > 1 {$2 = gensub(/^pvc-[^_]+_/, "", "g", $2); print}' \
    | sort -h \
    | awk '{printf "%-20s %-50s\n", $1, $2}'
