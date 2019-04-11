# Setup fzf
# ---------
if [[ ! "$PATH" == */home/navin/.fzf/bin* ]]; then
  export PATH="${PATH:+${PATH}:}/home/navin/.fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/home/navin/.fzf/shell/completion.bash" 2> /dev/null

# Key bindings
# ------------
source "/home/navin/.fzf/shell/key-bindings.bash"
