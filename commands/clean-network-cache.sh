#!/usr/bin/env bash

set -euo pipefail

echo "=== Network Cache Cleanup ==="

# Must run as root
if [[ $EUID -ne 0 ]]; then
    echo "Please run as root (sudo)." >&2
    exit 1
fi

echo
echo "[1/4] Flushing route cache..."
ip route flush cache 2>/dev/null || true

echo
echo "[2/4] Flushing ARP/NDP neighbor cache..."
ip neigh flush all 2>/dev/null || true

echo
echo "[3/4] Flushing DNS cache..."

if command -v resolvectl >/dev/null 2>&1; then
    resolvectl flush-caches
    echo "Flushed systemd-resolved cache."
elif command -v systemd-resolve >/dev/null 2>&1; then
    systemd-resolve --flush-caches
    echo "Flushed systemd-resolved cache."
else
    echo "No supported DNS cache service found."
fi

echo
echo "[4/4] Displaying current routes..."
ip route show

echo
echo "Done."
