if [ -z "$DISPLAY" ] && [ -n "$XDG_VTNR" ] && [ "$XDG_VTNR" -eq 1 ]; then
    XKB_DEFAULT_LAYOUT=us exec sway
  # exec startx
fi
