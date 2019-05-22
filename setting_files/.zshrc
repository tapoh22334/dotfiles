# zeshrc
autoload -Uz promptinit
promptinit
prompt fade green

autoload -U compinit
compinit

#export LANG=ja_JP.UTF-8
export LANG=en_US.UTF-8
export LSCOLORS=gxfxxxxxcxxxxxxxxxgxgx

#function
function mkcd(){
  if [[ -d $1 ]]; then
    echo "$1 already exists!"
    cd $1
  else
    mkdir -p $1 && cd $1
  fi
}

# alias
alias l='ls -G'
alias ll='ls -l -G'
alias la='ls -a -G'

if [[ ! -n $TMUX ]]; then
  tmux new-session
fi

# vi keymap
bindkey -v

bindkey '^R' history-incremental-search-backward
