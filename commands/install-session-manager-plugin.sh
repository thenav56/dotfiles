#!/usr/bin/env bash
# Install the latest AWS Session Manager plugin binary into ~/.local/bin (no root required).
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
BASE_URL="https://s3.amazonaws.com/session-manager-downloads/plugin/latest"

case "$(uname -m)" in
  x86_64|amd64)  pkg_arch="ubuntu_64bit" ;;
  aarch64|arm64) pkg_arch="ubuntu_arm64" ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

for cmd in curl bsdtar; do
  command -v "$cmd" >/dev/null || { echo "Missing required command: $cmd" >&2; exit 1; }
done

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

url="$BASE_URL/$pkg_arch/session-manager-plugin.deb"
echo "Downloading $url"
curl -fsSL -o "$tmp/plugin.deb" "$url"

# A .deb is an ar archive containing data.tar.*; bsdtar handles both layers.
bsdtar -xf "$tmp/plugin.deb" -C "$tmp"
data_tar="$(find "$tmp" -maxdepth 1 -name 'data.tar*' | head -n1)"
[[ -n "$data_tar" ]] || { echo "data.tar not found in package" >&2; exit 1; }
bsdtar -xf "$data_tar" -C "$tmp" ./usr/local/sessionmanagerplugin/bin/session-manager-plugin

mkdir -p "$INSTALL_DIR"
install -m 0755 "$tmp/usr/local/sessionmanagerplugin/bin/session-manager-plugin" "$INSTALL_DIR/session-manager-plugin"

echo "Installed session-manager-plugin $("$INSTALL_DIR/session-manager-plugin" --version) to $INSTALL_DIR"

case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *) echo "Note: $INSTALL_DIR is not on your PATH; add it so the AWS CLI can find the plugin." ;;
esac
