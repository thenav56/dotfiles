#!/bin/env zsh

BASE_PATH="$HOME/.local/share/zinit/completions/__nav__"

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

declare -A MY_COMMANDS
MY_COMMANDS=(
  # Teleport cli tools
  ["tsh"]="tsh --completion-script-zsh"
  ["tctl"]="tctl --completion-script-zsh"
  ["tbot"]="tbot --completion-script-zsh"
  # python
  ["pyenv"]="pyenv init -"
  ["pyenv-virtualenv"]="pyenv virtualenv-init -"
  # git
  ["git-lfs"]="git lfs completion zsh"
)

for command completion_command in "${(@kv)MY_COMMANDS}"; do
  if type "$command" > /dev/null && [ ! -f "${BASE_PATH}_${command}" ]; then
    eval "${completion_command}" > "${BASE_PATH}_${command}"
  fi
done

# Try to load FZF
[ -s "$FZF_KEY_BINDINGS" ] && source "$FZF_KEY_BINDINGS"

if [ -s "$FZF_COMPLETION" ]; then
    source "$FZF_COMPLETION"

    [ -s "$HOME/.dotfiles/tools/fzf-git/fzf-git.sh" ] &&\
        source "$HOME/.dotfiles/tools/fzf-git/fzf-git.sh"

    # Custom
    # ---- Teleport
    _fzf_complete_tsh() {
      _fzf_complete --no-select-1 --multi --reverse --header-lines=0 -- "$@" < <(~/.dotfiles/commands/_tsh_ssh clusters)
    }
fi

# Make sure to load this after fzf
if type "atuin" > /dev/null; then eval "$(atuin init zsh --disable-up-arrow)"; fi
