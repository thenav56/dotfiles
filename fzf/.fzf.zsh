# Setup fzf
# ---------
if [[ ! "$PATH" == */home/pandaman/.fzf/bin* ]]; then
  export PATH="${PATH:+${PATH}:}/home/pandaman/.fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/home/pandaman/.fzf/shell/completion.zsh" 2> /dev/null

# Key bindings
# ------------
source "/home/pandaman/.fzf/shell/key-bindings.zsh"
