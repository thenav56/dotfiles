#!/usr/bin/env bash

CLAUDE_AUTO_DUAL_THEME_FILE="$HOME/.claude/themes/auto-dual.json"

# Detect light/dark from the base16 theme slug
case "$BASE16_THEME" in
  *light*|*-day*|*dawn*|*latte*) base="light" ;;
  *)                             base="dark"  ;;
esac

echo "Updating claude theme with $BASE16_THEME ($base) -> $CLAUDE_AUTO_DUAL_THEME_FILE"

mkdir -p "$(dirname "$CLAUDE_AUTO_DUAL_THEME_FILE")"
printf '{"name":"Auto Dual","base":"%s"}\n' "$base" > "$CLAUDE_AUTO_DUAL_THEME_FILE"
