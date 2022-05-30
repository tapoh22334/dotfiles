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
antigen bundle 'endaaman/lxd-completion-zsh'

antigen apply

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# shellcheck source=/dev/null
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Editor
export EDITOR="/usr/bin/nvim"
alias vim='nvim'
if [[ ! -f "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim ]]; then
  curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# Env manager
if [[ -e "$HOME/.anyenv" ]]; then
  export ANYENV_ROOT="$HOME/.anyenv"
  export PATH="$ANYENV_ROOT/bin:$PATH"
  eval "$(anyenv init -)"
fi
_zshrc_notice_if_not_exist "$HOME/.anyenv"

# Remote access
if [[ -z $DISPLAY ]]; then
  export DISPLAY=localhost:0.0
fi
_zshrc_echo "DISPLAY=""$DISPLAY"


# settings for  WSL
if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null ; then
  _zshrc_echo "WSL"

  # Browser
  export BROWSER='/mnt/c/Program Files/Google/Chrome/Application/chrome.exe'
  function chrome () {
    "$BROWSER" "$1"
  }
  function chromefile () {
    chrome "$(wslpath -w "$(realpath "$1")")"
  }

  # open function
  function open() {
    if [ $# != 1 ]; then
      explorer.exe .
    else
      if [ -e "$1" ]; then
        cmd.exe /c start "$(wslpath -w "$1")" 2> /dev/null
      else
        echo "open: ""$1"" : No such file or directory" 
      fi
    fi
  }

  # X11 server
  if [[ $SHLVL -eq 1 ]] && ! xset q &>/dev/null; then
    '/mnt/c/Program Files/VcXsrv/xlaunch.exe' -run ~/.config.xlaunch
    _zshrc_echo "X server started"
  fi

  export DOCKER_HOST=tcp://192.168.11.13:2375
  _zshrc_echo "DOCKER_HOST=""$DOCKER_HOST"
  #if [[ $SHLVL -eq 1 ]] && ! pgrep -f docker > /dev/null; then
  #  sudo cgroupfs-mount && sudo service docker start
  #  :
  #fi
  #_zshrc_echo "docker daemon working"

else
  _zshrc_echo "Non WSL"
  ## TODO set browser
  export BROWSER=''
fi
_zshrc_notice_if_not_exist "$BROWSER"

if [[ -z "$SSH_CLIENT" ]]; then
  if ! ps -p "$SSH_AGENT_PID" &> /dev/null ; then
    eval "$(ssh-agent)"
  fi
  _zshrc_echo "ssh-agent is running"

  if ! ssh-add -l > /dev/null; then
    ssh-add ~/.ssh/id_rsa &> /dev/null
    _zshrc_echo "ssh key is added to the agent"
  fi
  _zshrc_echo "$(ssh-add -l)"
fi

autoload -Uz promptinit && promptinit
prompt clint
#autoload -U compinit && compinit

# vi keymap
bindkey -v

# shellcheck source=/dev/null
[ -f ~/.keybaind.zsh ] && source ~/.keybaind.zsh
_zshrc_notice_if_not_exist ~/.keybaind.zsh

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

export DOTFILES_HOME="$HOME/.dotfiles"

#function
function c() {
  builtin cd "$@" && ls -F
}

function mkcd(){
  mkdir -p "$1" && cd "$1" || return
}

function _zshrc_git_gen_message() {
    echo -n "Update " ; git diff --name-only | xargs echo
}

# alias
## ls
alias l='ls -G'
alias ll='ls -l -G'
alias la='ls -a -G'
## fzf
alias fcat='fzfcat'
alias fcd='fzfcd'
alias fvim='fzfvim'
## vim
alias viz='vim ~/.zshrc'
alias vivimrc='vim ~/.vimrc'
alias vicheat='vim ~/.local/share/navi/cheats/cheat'
alias vidot='vim ~/.dotfiles'
## navi
alias nvi='navi'
alias snvi='sudo navi --print'
## git
alias g='git'
alias gfs='git fetch && git status'
alias gcauto='git commit -am "$(_zshrc_git_gen_message)"'
## broot
alias bo="br --conf ~/.config/broot/select.toml"

## dotfiles
alias dt='vim $(bo $DOTFILES_HOME/dot -h)'
alias dthelp='find $DOTFILES_HOME -type f | grep .zshrc | xargs grep -e "^alias" -e "^function"'
alias dtcheck='(cd $DOTFILES_HOME; git fetch && git status) && shellcheck $DOTFILES_HOME/dot/.zshrc'

# local wiki
export WIKI_HOME="$HOME/wiki"
_zshrc_notice_if_not_exist "$WIKI_HOME"
alias wk='(cd $WIKI_HOME && git pull && vim +VimwikiIndex && gcauto && git push)'

# shellcheck source=/dev/null
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
_zshrc_notice_if_not_exist ~/.fzf.zsh

export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -l -g ""'
export FZF_DEFAULT_OPTS='--no-height --no-reverse'
export FZF_CTRL_T_OPTS="--preview '(highlight -O ansi -l {} 2> /dev/null || cat {} || tree -C {}) 2> /dev/null | head -200'"
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview'"

# shellcheck source=/dev/null
[ -f ~/.misc.zsh ] && source ~/.misc.zsh
_zshrc_notice_if_not_exist ~/.misc.zsh

export PATH="$PATH:/home/linuxbrew/.linuxbrew/bin"
export PATH="$PATH:/usr/local/opt/postgresql@11/bin"
export PATH="$PATH:/home/$USER/.local/bin"
export PATH="$PATH:$HOME/bin"

#export PATH=$PATH:$HOME/.fasd/bin
#eval "$(fasd --init auto)"

# shellcheck source=/dev/null
source "$HOME"/.config/broot/launcher/bash/br
_zshrc_notice_if_not_exist "$HOME"/.config/broot/launcher/bash/br

# tmux
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi
if [[ -z "$SSH_CLIENT" && $SHLVL -eq 1 ]]; then
  tmux attach || tmux new
fi

export TS_SOCK_NET=/var/tmp/socket.net
export TS_SOCK_CPU=/var/tmp/socket.cpu
export TS_SOCK_DISK=/var/tmp/socket.disk
alias tspnet='TS_SOCKET=$TS_SOCK_NET tsp'
alias tspcpu='TS_SOCKET=$TS_SOCK_CPU tsp'
alias tspdisk='TS_SOCKET=$TS_SOCK_DISK tsp'

function tsprelaunch () {
    (
        export TS_SOCKET=$TS_SOCK_NET; \
        while read -r n; do \
            tsp -i "$n" | grep Command | sed -e "s/Command: //g" | xargs tsp ;\
        done < <(tsp -l | tr -s ' ' | awk '/finished/{ if ($4 == 1) { print $1 } }') ; \
    )
}

function tsp_queue_print_summary () {
    TARGET="$1"
                                        echo "$TARGET"
    TS_SOCKET="$TARGET" tsp -l \
        | tee \
        >(grep finished | wc -l | xargs echo "     |- finished : ") \
        >(grep running  | wc -l | xargs echo "     |- running  : ") \
        >(grep queued   | wc -l | xargs echo "     |- queued   : ") \
        &> /dev/null
}

function tsp_print_summary () {
    LIGHT_GREEN='\033[1;32m'
    NC='\033[0m' # No Color
    echo "${LIGHT_GREEN}●${NC} task-spooler"
    paste <(tsp_queue_print_summary $TS_SOCK_NET) \
          <(tsp_queue_print_summary $TS_SOCK_CPU) \
          <(tsp_queue_print_summary $TS_SOCK_DISK)
}
tsp_print_summary

export XAUTHORITY=$HOME/.Xauthority

# shellcheck source=/dev/null
source /home/iwase/.config/broot/launcher/bash/br
