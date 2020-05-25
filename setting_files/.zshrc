# zeshrc

ANTIGEN_PATH=~/.cache/antigen/antigen.zsh
if [[ ! -f ${ANTIGEN_PATH} ]]; then
    curl -L git.io/antigen > ${ANTIGEN_PATH}
fi

if [[ -f ${ANTIGEN_PATH} ]]; then
    source ${ANTIGEN_PATH}
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
  if ! xset q &>/dev/null; then
    /mnt/c/Program\ Files/VcXsrv/xlaunch.exe
  else;
    echo "X server working"
  fi

else;
  echo "not wsl"
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

function fcd() {
  local dir
  dir=$(find ${1:-.} -path '*/\.*' -prune \
          -o -type d -print 2> /dev/null | fzf +m) &&
  cd "$dir"
}

# alias
alias l='ls -G'
alias ll='ls -l -G'
alias la='ls -a -G'
alias vim='nvim'

export PATH=$PATH:$HOME/.fasd/bin
eval "$(fasd --init auto)"

# vi keymap
bindkey -v

bindkey '^R' history-incremental-search-backward

local FILE=~/.fzf.zsh;                [ -f $FILE ] && source $FILE || echo "$FILE not found"
local FILE=~/.line;                   [ -f $FILE ] && source $FILE || echo "$FILE not found"
local FILE=~/.uma_aws;                [ -f $FILE ] && source $FILE || echo "$FILE not found"
local FILE=~/uma_gen10/startenv.sh;   [ -f $FILE ] && source $FILE || echo "$FILE not found"

alias uma='source ~/uma/startenv.sh'
alias vim='nvim'

export PATH="/usr/local/opt/postgresql@11/bin:$PATH"

