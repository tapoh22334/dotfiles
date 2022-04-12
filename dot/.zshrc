#!/bin/bash

function _zshrc_echo () {
  echo "[zshrc]:" "$@"
}

function _zshrc_notice_if_not_exist () {
  if [[ ! -e "$1" ]]; then
    _zshrc_echo \" "$1" \" "is not found"
  fi
}

ANTIGEN_PATH=~/.cache/antigen/antigen.zsh
if [[ ! -f ${ANTIGEN_PATH} ]]; then
  mkdir -p "$(dirname ${ANTIGEN_PATH})"
  wget git.io/antigen -O ${ANTIGEN_PATH}
fi

# shellcheck disable=SC1090
source "${ANTIGEN_PATH}"
antigen use oh-my-zsh

# Load bundles from the default repo (oh-my-zsh)
antigen theme romkatv/powerlevel10k

antigen apply

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# shellcheck source=/dev/null
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Editor
alias vim='nvim'
if [[ ! -f "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim ]]; then
  curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

if [[ -e "$HOME/.anyenv" ]]; then
    export ANYENV_ROOT="$HOME/.anyenv"
    export PATH="$ANYENV_ROOT/bin:$PATH"
    eval "$(anyenv init -)"
fi
_zshrc_notice_if_not_exist "$HOME/.anyenv"

## settings for  WSL
if uname -r | grep -i 'microsoft' >/dev/null ; then
  _zshrc_echo "WSL"

  ## Browser
  export BROWSER='/mnt/c/Program Files/Google/Chrome/Application/chrome.exe'
  function chrome () {
    "$BROWSER" "$1"
  }
  function chromefile () {
    chrome "$(wslpath -w "$(realpath "$1")")"
  }
  _zshrc_notice_if_not_exist "$BROWSER"

  # X11 server
  #if [[ $SHLVL -eq 1 ]] && ! xset q &>/dev/null; then
  #  '/mnt/c/Program Files/VcXsrv/xlaunch.exe' -run ~/.config.xlaunch
  #  _zshrc_echo "X server started"
  #fi

  #if [[ $SHLVL -eq 1 ]] && ! pgrep -f docker > /dev/null; then
  #  sudo cgroupfs-mount && sudo service docker start
  #  :
  #fi
  #_zshrc_echo "docker daemon working"

else
  _zshrc_echo "Linux"
fi

if [[ -z $DISPLAY ]]; then
  export DISPLAY=:0.0
fi

# tmux 
if [[ $SHLVL -eq 1 ]]; then
  tmux attach || tmux new
fi

autoload -Uz promptinit && promptinit
prompt clint
autoload -U compinit && compinit

# vi keymap
bindkey -v
bindkey '^R' history-incremental-search-backward

setopt no_beep
setopt auto_cd
setopt auto_pushd

export HISTFILE=${HOME}/.zsh_history
export HISTSIZE=100000
export SAVEHIST=100000
setopt hist_ignore_dups
setopt hist_save_no_dups
setopt EXTENDED_HISTORY

export LANG=en_US.UTF-8
export LSCOLORS=gxfxxxxxcxxxxxxxxxgxgx

#function
function c() {
  builtin cd "$@" && ls -F
}

function mkcd(){
  mkdir -p "$1" && cd "$1" || return
}

# alias
alias l='ls -G'
alias ll='ls -l -G'
alias la='ls -a -G'
alias fcat='fzfcat'
alias fcd='fzfcd'
alias fvim='fzfvim'

# shellcheck source=/dev/null
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
_zshrc_notice_if_not_exist ~/.fzf.zsh

export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -l -g ""'
export FZF_DEFAULT_OPTS='--no-height --no-reverse'
# Using highlight (http://www.andre-simon.de/doku/highlight/en/highlight.html)
export FZF_CTRL_T_OPTS="--preview '(highlight -O ansi -l {} 2> /dev/null || cat {} || tree -C {}) 2> /dev/null | head -200'"
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview'"

# shellcheck source=/dev/null
[ -f ~/.misc.zsh ] && source ~/.misc.zsh
_zshrc_notice_if_not_exist ~/.misc.zsh

export PATH="/usr/local/opt/postgresql@11/bin:$PATH"
export PATH="$PATH:/home/$USER/.local/bin"
export PATH="$PATH:$HOME/bin"

#export PATH=$PATH:$HOME/.fasd/bin
#eval "$(fasd --init auto)"
