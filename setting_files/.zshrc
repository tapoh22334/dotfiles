# zeshrc

ANTIGEN_PATH=~/.cache/antigen/antigen.zsh
if [[ ! -f ${ANTIGEN_PATH} ]]; then
    mkdir -p $(dirname ${ANTIGEN_PATH})
    wget git.io/antigen -O ${ANTIGEN_PATH}
fi

if [[ -f ${ANTIGEN_PATH} ]]; then
    source ${ANTIGEN_PATH}
    # Load bundles from the default repo (oh-my-zsh)
    antigen use oh-my-zsh
    antigen bundle git
    antigen bundle docker
fi

## xserver
if [[ -z $DISPLAY ]]; then
  export DISPLAY=:0.0
fi

## settings for  WSL
if uname -r | grep -i 'microsoft' >/dev/null ; then
  echo "wsl"
  export BROWSER='/mnt/c/Program\ Files\ \(x86\)/Google/Chrome/Application/chrome.exe'
  alias chrome='exec /mnt/c/Program\ Files\ \(x86\)/Google/Chrome/Application/chrome.exe "$@"'
  alias chromecors='exec /mnt/c/Program\ Files\ \(x86\)/Google/Chrome/Application/chrome.exe --disable-web-security --user-data-dir "$@"'

  # vcxserv
  if [[ $SHLVL -eq 1 ]] && ! xset q &>/dev/null; then
    /mnt/c/Program\ Files/VcXsrv/xlaunch.exe -run ~/.config.xlaunch
  else;
    echo "X server working"
  fi

  if [[ $SHLVL -eq 1 ]] && ! pgrep -f docker > /dev/null; then
    #sudo cgroupfs-mount && sudo service docker start
    :
  else;
    echo "docker daemon working"
  fi

else;
  echo "linux"
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

setopt no_beep
setopt auto_cd
setopt auto_pushd

#export LANG=ja_JP.UTF-8
export LANG=en_US.UTF-8
export LSCOLORS=gxfxxxxxcxxxxxxxxxgxgx
export DISPLAY=:0.0

#function

function c() {
  builtin cd "$@" && ls -F
}

function mkcd(){
  if [[ -d $1 ]]; then
    echo "$1 already exists!"
    cd $1
  else
    mkdir -p $1 && cd $1
  fi
}

function fcat() {
  fzf --preview 'cat {}'
}

function fd() {
  local dir
  dir=$(find ${1:-.} -path '*/\.*' -prune \
          -o -type d -print 2> /dev/null | fzf --height 40% --reverse) &&
  cd "$dir"
}

alias fv='vim $(fzf --height 40% --reverse)'

# alias
alias l='ls -G'
alias ll='ls -l -G'
alias la='ls -a -G'
alias vim='nvim'

#export PATH=$PATH:$HOME/.fasd/bin
#eval "$(fasd --init auto)"

# vi keymap
bindkey -v

export HISTFILE=${HOME}/.zsh_history
export HISTSIZE=5000
export SAVEHIST=100000
setopt hist_ignore_dups
setopt hist_save_no_dups
setopt EXTENDED_HISTORY
bindkey '^R' history-incremental-search-backward

local FILE=~/.fzf.zsh;                [ -f $FILE ] && source $FILE || echo "$FILE not found"
local FILE=~/.line;                   [ -f $FILE ] && source $FILE || echo "$FILE not found"
local FILE=~/.uma_aws;                [ -f $FILE ] && source $FILE || echo "$FILE not found"
local FILE=~/uma2/startenv.sh;        [ -f $FILE ] && source $FILE || echo "$FILE not found"

alias uma='source ~/uma/startenv.sh'
alias vim='nvim'

export PATH="/usr/local/opt/postgresql@11/bin:$PATH"

