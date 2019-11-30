export ZSH=$HOME/.oh-my-zsh

# ZSH_THEME="robbyrussell-custom"
ZSH_THEME="${ZSH_THEME:-ys}"

plugins=(
    git vi-mode yarn
    docker docker-compose
    zsh_reload wd
    django fancy-ctrl-z shrink-path
    colored-man-pages rsync

    # External plugins
    zsh-syntax-highlighting  # https://github.com/zsh-users/zsh-syntax-highlighting
    zsh-autosuggestions      # https://github.com/zsh-users/zsh-autosuggestions
    # git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

# History Configuration
HISTSIZE=10000000
SAVEHIST=10000000

setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY               # Don't execute immediately upon history expansion.

export PATH=${PATH}:${HOME}/.local/bin/
export PATH=${PATH}:"/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/lib/jvm/default/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl"

export EDITOR=vim
export VISUAL=$EDITOR
export RIPGREP_CONFIG_PATH=$HOME/.ripgreprc

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# this would bind ctrl + space to accept the current suggestion.
bindkey '^ ' autosuggest-accept

alias vi=$EDITOR
alias python=python3
alias tmux="TERM=screen-256color-bce tmux"
alias ssh='TERM=screen ssh'
alias day='base16_gruvbox-light-hard'
alias night='base16_gruvbox-dark-hard'
alias gpush='git push -u origin $(git rev-parse --abbrev-ref HEAD)'
alias start='swaymsg exec'

# Use wayland
# export XDG_CURRENT_DESKTOP=Unity
# export GDK_BACKEND=wayland
# export QT_QPA_PLATFORM=wayland
# export CLUTTER_BACKEND=wayland
# export SDL_VIDEODRIVER=wayland

# Returns whether the given command is executable or aliased.
_has() {
  return $( whence $1 >/dev/null )
}

# load virtualenv from ~/.venv
function venvactive() {
    $(envactive)
}

# added by travis gem
[ -f /home/navin/.travis/travis.sh ] && source /home/navin/.travis/travis.sh

if [[ $TERM == xterm-termite ]]; then
    source /etc/profile.d/vte.sh
  __vte_osc7
fi

[ -f ~/.fzf.zsh  ] && source ~/.fzf.zsh
# fzf + rg configuration
if _has fzf && _has rg; then
  export FZF_DEFAULT_COMMAND="rg -i --files --no-ignore --follow --hidden 2> /dev/null"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Colorscheme installation from https://github.com/chriskempson/base16-shell
BASE16_SHELL=$HOME/.config/base16-shell/
export BASE16_SHELL_HOOKS=$BASE16_SHELL/hooks
[ -n "$PS1" ] && [ -s $BASE16_SHELL/profile_helper.sh ] && eval "$($BASE16_SHELL/profile_helper.sh)"
