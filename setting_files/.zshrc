# zeshrc

ANTIGEN_PATH=~/.cache/antigen/antigen.zsh
if [[ ! -f ${ANTIGEN_PATH} ]]; then
    curl -L git.io/antigen > ${ANTIGEN_PATH}
fi

if [[ -f ${ANTIGEN_PATH} ]]; then
    source ${ANTIGEN_PATH}
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
function mkcd(){
  if [[ -d $1 ]]; then
    echo "$1 already exists!"
    cd $1
  else
    mkdir -p $1 && cd $1
  fi
}

function fcd() {
  local dir
  dir=$(find ${1:-.} -path '*/\.*' -prune \
          -o -type d -print 2> /dev/null | fzf +m) &&
  cd "$dir"
}

function cd {
  builtin cd "$@" && ls -F
}

# alias
alias l='ls -G'
alias ll='ls -l -G'
alias la='ls -a -G'

export PATH=$PATH:$HOME/.fasd/bin
eval "$(fasd --init auto)"

# vi keymap
bindkey -v

bindkey '^R' history-incremental-search-backward

local FILE=~/.fzf.zsh;                [ -f $FILE ] && source $FILE || echo "$FILE not found"
local FILE=~/.line;                   [ -f $FILE ] && source $FILE || echo "$FILE not found"
local FILE=~/.uma_aws;                [ -f $FILE ] && source $FILE || echo "$FILE not found"
local FILE=~/uma_gen03/startenv.sh;   [ -f $FILE ] && source $FILE || echo "$FILE not found"

alias uma='source ~/uma/startenv.sh'


