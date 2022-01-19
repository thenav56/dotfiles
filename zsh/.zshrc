export ZSH=$HOME/.oh-my-zsh

# ZSH_THEME="robbyrussell-custom"
ZSH_THEME="${ZSH_THEME:-ys}"

plugins=(
    git vi-mode yarn
    poetry
    docker docker-compose
    zsh_reload wd
    django fancy-ctrl-z shrink-path
    colored-man-pages rsync
    zsh-completions  # https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions

    # External plugins
    zsh-syntax-highlighting  # https://github.com/zsh-users/zsh-syntax-highlighting
    zsh-autosuggestions      # https://github.com/zsh-users/zsh-autosuggestions
    # git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    # git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh
fpath=($HOME/.config/zsh-completions/ $fpath)
autoload -U compinit && compinit

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

export GEM_HOME="$HOME/gems"
export GOPATH="$HOME/.go"
export PATH=${PATH}:${HOME}/.local/bin/
export PATH=${PATH}:"/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/lib/jvm/default/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl"
export PATH=${PATH}:"$HOME/gems/bin:$HOME/.gem/ruby/2.6.0/bin"
export PATH=${PATH}:"$GOPATH/bin"
export PATH=${PATH}:"/home/linuxbrew/.linuxbrew/bin"
export PIPENV_PYTHON="$PYENV_ROOT/shims/python"

export EDITOR=nvim
export VISUAL=$EDITOR
export RIPGREP_CONFIG_PATH=$HOME/.ripgreprc
export DOCKER_BUILDKIT=1

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# NVR (Neovim remote command send)
export NVIM_LISTEN_ADDRESS=/tmp/nvimsocket

# this would bind ctrl + space to accept the current suggestion.
bindkey '^ ' autosuggest-accept

# Used by nvim and zsh for changing themes and alias day/night
export BASE16_DAY_THEME='base16_gruvbox-light-hard'
export BASE16_NIGHT_THEME='base16_solarflare'

alias vi=$EDITOR
alias python=python3
alias tmux="TERM=screen-256color-bce tmux"
alias ssh='TERM=screen ssh'
alias day="$BASE16_DAY_THEME; git config --global split-diffs.theme-name github-light; gsettings set org.gnome.desktop.interface gtk-theme Arc"
alias night="$BASE16_NIGHT_THEME; git config --global split-diffs.theme-name github-dark-dim; gsettings set org.gnome.desktop.interface gtk-theme Arc-Dark"
alias gpush='git push -u origin $(git rev-parse --abbrev-ref HEAD)'
alias start='swaymsg exec'
alias bat='bat --theme base16'
alias cat='bat --theme base16'
alias lcat='lolcat'
alias rgc='rg --color always'
alias serverless='npx serverless'
alias sls='npx serverless'
alias yay="yay --sudoflags='-B'"
alias docker-images="docker images --format '{{.Size}}\t{{.Repository}}:{{.Tag}}\t{{.ID}}' | sort -hr | column -t"

# export WAYLAND_DISPLAY=true
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

_has fzf && source /usr/share/fzf/key-bindings.zsh

[[ -r "/usr/share/z/z.sh" ]] && source /usr/share/z/z.sh

# fzf + rg configuration
if _has fzf && _has rg; then
    export FZF_DEFAULT_COMMAND="rg -i --files --no-ignore --follow --hidden 2> /dev/null"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_THEME_CONFIG='
    --color fg:#D8DEE9,bg:#2E3440,hl:#A3BE8C,fg+:#D8DEE9,bg+:#434C5E,hl+:#A3BE8C
    --color pointer:#BF616A,info:#4C566A,spinner:#4C566A,header:#4C566A,prompt:#81A1C1,marker:#EBCB8B
    '
    export FZF_DEFAULT_OPTS=$FZF_THEME_CONFIG
fi

# Colorscheme installation from https://github.com/chriskempson/base16-shell
BASE16_SHELL=$HOME/.config/base16-shell/
export BASE16_SHELL_HOOKS=$BASE16_SHELL/hooks
[ -n "$PS1" ] && [ -s $BASE16_SHELL/profile_helper.sh ] && eval "$($BASE16_SHELL/profile_helper.sh)"

# Added by serverless binary installer
export PATH="$HOME/.serverless/bin:$PATH"

export PATH="$HOME/.poetry/bin:$PATH"

if type "pyenv" > /dev/null; then eval "$(pyenv init -)"; fi

source /home/navin/.config/broot/launcher/bash/br
[[ -r "/opt/git-subrepo/.rc" ]] && source /opt/git-subrepo/.rc

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
