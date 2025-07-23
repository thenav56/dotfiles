#!/bin/bash

PATH="$PATH":"/opt/homebrew/bin/"

# Get the ID of the current window (the fzf overlay or active shell)
current_window_id="$KITTY_WINDOW_ID"

# Get the full layout and identify the current tab
current_tab_id=$(kitty @ ls |
  jq --argjson win_id "$current_window_id" '
    .[] | .tabs[] |
    select(.windows[].id == $win_id) |
    .id
  ')

# Now list all other windows NOT in the current tab
kitty @ ls |
jq -r --argjson skip_tab "$current_tab_id" '
  .[] |
  .tabs[] |
  select(.id != $skip_tab) |
  .windows[] |
  {id: .id, cmd: .foreground_processes[-1].cmdline | join(" ")} |
  "\(.id): \(.cmd)"
' |
fzf --prompt="Focus window by command: " |
cut -d: -f1 |
xargs -r -I {} kitty @ focus-window --match id:{}
