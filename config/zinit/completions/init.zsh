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
  # krew
  ["kubectl-cnpg"]='kubectl cnpg completion zsh'
  # Misc
  ["bun"]='source "/home/navin/.bun/_bun"'
  ["task"]='task --completion zsh'
  ["tenv"]='tenv completion zsh'
  # typer CLIs (custom tools) — replaces the hand-maintained ~/.zfunc stubs
  ["gh_monitor"]='gh_monitor --show-completion'
  ["togglectl"]='togglectl --show-completion'
)

# Teleport's tsh/tctl emit completion *scripts* whose leading `#compdef` is empty,
# so compinit can't autoload them — they must be sourced. zinit's compdef shim
# captures the compdef call; zicdreplay (atload) registers it after compinit.
declare -a SOURCE_COMPLETIONS=(tsh tctl)

for command completion_command in "${(@kv)MY_COMMANDS}"; do
  type "$command" > /dev/null || continue
  cache="${BASE_PATH}_${command}"
  [ -f "$cache" ] || eval "${completion_command}" > "$cache"
  if (( ${SOURCE_COMPLETIONS[(Ie)$command]} )); then
    source "$cache"
  fi
done

# Try to load FZF
[ -s "$FZF_KEY_BINDINGS" ] && source "$FZF_KEY_BINDINGS"

if [ -s "$FZF_COMPLETION" ]; then
    source "$FZF_COMPLETION"

    if [ -s "$HOME/.dotfiles/tools/fzf-git/fzf-git.sh" ]; then
        source "$HOME/.dotfiles/tools/fzf-git/fzf-git.sh"

        # https://github.com/junegunn/fzf-git.sh/blob/34cd6c9d315d9b59b94721bd602c5769e919d686/fzf-git.sh#L173-L181
        _fzf_git_fzf() {
          fzf --height 90% --tmux 90%,70% \
            --layout reverse --multi --min-height 20+ --border \
            --no-separator --header-border horizontal \
            --border-label-pos 2 \
            --color 'label:blue' \
            --preview-window 'right,50%' --preview-border line \
            --bind 'ctrl-/:change-preview-window(down,50%|hidden|)' "$@"
        }
    fi

    # Custom
    # ---- Teleport
    _fzf_complete_tsh() {
      _fzf_complete --no-select-1 --multi --reverse --header-lines=0 -- "$@" < <(~/.dotfiles/commands/_tsh_ssh clusters)
    }

    # ---- ArgoCD
    _fzf_complete_argocd() {
       # kubie ctx <context> -n <argocd-ns> is required for using --core
      _fzf_complete --no-select-1 --multi --reverse --header-lines=0 -- "$@" < <(argocd.sh apps)
    }

    _fzf_complete_argocd.sh() {
      _fzf_complete --no-select-1 --multi --reverse --header-lines=0 -- "$@" < <(argocd.sh apps)
    }
fi

# Make sure to load this after fzf
if type "atuin" > /dev/null; then eval "$(atuin init zsh --disable-up-arrow)"; fi
