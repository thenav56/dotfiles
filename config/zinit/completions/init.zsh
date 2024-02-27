#!/bin/env zsh

if [[ "$OSTYPE" == "darwin"* ]]; then
    # MacOS
    # -- FZF
    FZF_KEY_BINDINGS="$(brew --prefix)/opt/fzf/shell/key-bindings.zsh"
    FZF_COMPLETION="$(brew --prefix)/opt/fzf/shell/completion.zsh"
else
    # Linux
    # -- FZF
    FZF_KEY_BINDINGS="/usr/share/fzf/key-bindings.zsh"
    FZF_COMPLETION="/usr/share/fzf/completion.zsh"
fi

if type "zoxide" > /dev/null; then eval "$(zoxide init zsh --no-cmd)"; fi
if type "pyenv" > /dev/null; then eval "$(pyenv init -)"; fi
if type "pyenv-virtualenv" > /dev/null; then eval "$(pyenv virtualenv-init -)"; fi
if type "k9s" > /dev/null; then source <(k9s completion zsh); fi

# Try to load FZF
[ -s "$FZF_KEY_BINDINGS" ] && source "$FZF_KEY_BINDINGS"
[ -s "$FZF_COMPLETION" ] && source "$FZF_COMPLETION"

# Make sure to load this after fzf
if type "atuin" > /dev/null; then eval "$(atuin init zsh --disable-up-arrow)"; fi
