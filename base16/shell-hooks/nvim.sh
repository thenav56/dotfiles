#!/usr/bin/env bash

set -euo pipefail

BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RESET='\033[0m'

theme="${VIM_ACTIVE_THEME:?VIM_ACTIVE_THEME not set}"
theme_display="${BLUE}$theme${RESET}"

echo -e "Updating neovim instances with $theme_display"
nvr --serverlist 2>/dev/null |
while read -r s; do
    [[ $s == *.0 ]] || continue
    echo " - Updating $s"
    nvr --servername "$s" --nostart -c "colorscheme $theme"
done

echo -e " - * Updating ${YELLOW}$VIM_ACTIVE_THEME_FILE${RESET} with $theme_display"
[[ -n ${VIM_ACTIVE_THEME_FILE:-} ]] &&
    printf '%s\n' "$theme" > "$VIM_ACTIVE_THEME_FILE"
