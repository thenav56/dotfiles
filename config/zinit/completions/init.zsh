#!/bin/env zsh

if [[ "$OSTYPE" == "darwin"* ]]; then
    # MacOS
    # -- FZF
    if type "brew" > /dev/null; then
        FZF_KEY_BINDINGS="$(brew --prefix)/opt/fzf/shell/key-bindings.zsh"
        FZF_COMPLETION="$(brew --prefix)/opt/fzf/shell/completion.zsh"
    fi
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

# Teleport cli tools
if type "tsh" > /dev/null; then eval "$(tsh --completion-script-zsh)"; fi
if type "tctl" > /dev/null; then eval "$(tctl --completion-script-zsh)"; fi
if type "tbot" > /dev/null; then eval "$(tbot --completion-script-zsh)"; fi

# Try to load FZF
[ -s "$FZF_KEY_BINDINGS" ] && source "$FZF_KEY_BINDINGS"

if [ -s "$FZF_COMPLETION" ]; then
    source "$FZF_COMPLETION"

    [ -s "$HOME/.dotfiles/tools/fzf-git/fzf-git.sh" ] &&\
        source "$HOME/.dotfiles/tools/fzf-git/fzf-git.sh"

    # Custom
    # ---- Teleport
    _fzf_complete_tsh() {
      _fzf_complete --no-select-1 --multi --reverse --header-lines=0 -- "$@" < <(tsh_clusters)
    }
fi

# Make sure to load this after fzf
if type "atuin" > /dev/null; then eval "$(atuin init zsh --disable-up-arrow)"; fi
