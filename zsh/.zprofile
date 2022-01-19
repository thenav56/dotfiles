export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if type "pyenv" > /dev/null; then eval "$(pyenv init --path)"; fi

if [ -z "$DISPLAY" ] && [ -n "$XDG_VTNR" ] && [ "$XDG_VTNR" -eq 1 ]; then
    export QT_QPA_PLATFORMTHEME=qt5ct
    export XDG_CURRENT_DESKTOP=sway
    export XKB_DEFAULT_LAYOUT=us
    export MOZ_ENABLE_WAYLAND=1
    # export LIBSEAT_BACKEND=logind
    exec sway
  # exec startx
fi
