# Setup fzf
# ---------
if [[ ! "$PATH" == */home/water/.fzf/bin* ]]; then
  export PATH="$PATH:/home/water/.fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/home/water/.fzf/shell/completion.bash" 2> /dev/null

# Key bindings
# ------------
source "/home/water/.fzf/shell/key-bindings.bash"

