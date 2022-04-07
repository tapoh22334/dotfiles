#!/bin/bash

function zshrc_echo () {
    echo "[zshrc]:" "$@"
}

ANTIGEN_PATH=~/.cache/antigen/antigen.zsh
if [[ ! -f ${ANTIGEN_PATH} ]]; then
    mkdir -p "$(dirname ${ANTIGEN_PATH})"
    wget git.io/antigen -O ${ANTIGEN_PATH}
fi

#shellcheck disable=SC1090
source "${ANTIGEN_PATH}"
# Load bundles from the default repo (oh-my-zsh)
antigen use oh-my-zsh
antigen apply

## xserver
if [[ -z $DISPLAY ]]; then
  export DISPLAY=:0.0
fi

## settings for  WSL
if uname -r | grep -i 'microsoft' >/dev/null ; then
  zshrc_echo "WSL"
  export BROWSER='/mnt/c/Program\ Files\ \(x86\)/Google/Chrome/Application/chrome.exe'
  alias chrome='exec /mnt/c/Program\ Files\ \(x86\)/Google/Chrome/Application/chrome.exe'
  alias chromecors='exec /mnt/c/Program\ Files\ \(x86\)/Google/Chrome/Application/chrome.exe --disable-web-security --user-data-dir'

  # vcxserv
  if [[ $SHLVL -eq 1 ]] && ! xset q &>/dev/null; then
    /mnt/c/Program\ Files/VcXsrv/xlaunch.exe -run ~/.config.xlaunch
  fi

  zshrc_echo "X server working"

  #if [[ $SHLVL -eq 1 ]] && ! pgrep -f docker > /dev/null; then
  #  sudo cgroupfs-mount && sudo service docker start
  #  :
  #fi
  #zshrc_echo "docker daemon working"

else
  zshrc_echo "Linux"
fi

# tmux 
if [[ $SHLVL -eq 1 ]]; then
  tmux attach || tmux new
fi

autoload -Uz promptinit
promptinit
prompt clint

autoload -U compinit
compinit

# vi keymap
bindkey -v
bindkey '^R' history-incremental-search-backward

setopt no_beep
setopt auto_cd
setopt auto_pushd

export HISTFILE=${HOME}/.zsh_history
export HISTSIZE=5000
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
alias vim='nvim'
alias fcat='fzfcat'
alias fcd='fzfcd'
alias fvim='fzfvim'

export PATH="/usr/local/opt/postgresql@11/bin:$PATH"
export PATH="$HOME/bin:$PATH"
#export PATH=$PATH:$HOME/.fasd/bin
#eval "$(fasd --init auto)"

