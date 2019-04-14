# zeshrc
autoload -U compinit
compinit

export LANG=ja_JP.UTF-8
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

function vscode(){
  VSCODE_CWD="$PWD" open -n -b "com.microsoft.VSCode" --args $* ;
}

# alias
alias l='ls -G'
alias ll='ls -l -G'
alias la='ls -a -G'

bindkey -v

tmux
