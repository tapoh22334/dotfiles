#!/bin/bash

# Utility function for logging
log_info() {
  echo "[zshrc]:" "$@"
}

# Check if a file or directory exists
check_exist() {
  [[ ! -e "$1" ]] && log_info "\"$1\" not found"
}

# Setup Antigen for Zsh
setup_antigen() {
  local antigen_path="$HOME/.cache/antigen/antigen.zsh"
  if [[ ! -f ${antigen_path} ]]; then
    mkdir -p "$(dirname ${antigen_path})"
    wget -qO "${antigen_path}" git.io/antigen
  fi
  source "${antigen_path}"
  antigen use oh-my-zsh
  antigen theme romkatv/powerlevel10k
  antigen bundle 'endaaman/lxd-completion-zsh'
  antigen apply
}
setup_antigen

# Powerlevel10k configuration
setup_p10k() {
  [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh || p10k configure
}
setup_p10k

# Set default editor to Neovim
export EDITOR="/usr/bin/nvim"
alias vim='nvim'

# Install Vim-plug for Neovim
install_vim_plug() {
  local plug_path="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim"
  if [[ ! -f "${plug_path}" ]]; then
    curl -fLo "${plug_path}" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  fi
}
install_vim_plug

# Setup anyenv
setup_anyenv() {
  if [[ -d "$HOME/.anyenv" ]]; then
    export ANYENV_ROOT="$HOME/.anyenv"
    export PATH="$ANYENV_ROOT/bin:$PATH"
    eval "$(anyenv init -)"
  fi
}
check_exist "$HOME/.anyenv"
setup_anyenv

# Setup X11 forwarding for non-WSL environments
setup_x11() {
  if [[ -z "$DISPLAY" ]]; then
    export DISPLAY=$(ip route list default | awk '{print $3}'):0
    export LIBGL_ALWAYS_INDIRECT=1
  fi
  log_info "DISPLAY=\"$DISPLAY\""
}
setup_x11

# Setup for WSL environments
setup_wsl() {
  if grep -qEi "(Microsoft|WSL)" /proc/version; then
    log_info "WSL detected"
    alias ps1='powershell.exe'
    export BROWSER='/mnt/c/Program Files/Google/Chrome/Application/chrome.exe'
    setup_wsl_browser
    setup_x11_server
  else
    log_info "Non-WSL environment"
    export BROWSER=''
  fi
}
setup_wsl

# Setup browser function for WSL
setup_wsl_browser() {
  function chrome() {
    "$BROWSER" "$1"
  }
  function chromefile() {
    chrome "$(wslpath -w "$(realpath "$1")")"
  }
}

# Start X11 server on WSL
setup_x11_server() {
  if [[ $SHLVL -eq 1 ]] && ! xset q &>/dev/null; then
    '/mnt/c/Program Files/VcXsrv/xlaunch.exe' -run ~/.config.xlaunch &
    log_info "X server started"
  fi
}

# Setup SSH agent
setup_ssh_agent() {
  if [[ -z "$SSH_CLIENT" ]] && ! ps -p "$SSH_AGENT_PID" &>/dev/null; then
    eval "$(ssh-agent)"
    log_info "ssh-agent is running"
  fi
  if ! ssh-add -l > /dev/null; then
    ssh-add ~/.ssh/id_rsa &> /dev/null
    log_info "ssh key added to agent"
  fi
}
setup_ssh_agent

# Initialize prompt
initialize_prompt() {
  autoload -Uz promptinit && promptinit
  prompt clint
}
initialize_prompt

# Set vi keymap
set_vi_keymap() {
  bindkey -v
}
set_vi_keymap

# Load custom keybindings if available
load_keybindings() {
  local keybind_path="$HOME/.zshrc.d/.keybind.zsh"
  [[ -f "$keybind_path" ]] && source "$keybind_path"
  check_exist "$keybind_path"
}
load_keybindings

# History settings
setup_history() {
  setopt no_beep auto_cd auto_pushd
  export HISTFILE="$HOME/.zsh_history"
  export HISTSIZE=100000 SAVEHIST=100000
  setopt hist_ignore_dups hist_save_no_dups EXTENDED_HISTORY
}
setup_history

# Localization settings
setup_localization() {
  export LANG=en_US.UTF-8 LSCOLORS=gxfxxxxxcxxxxxxxxxgxgx
}
setup_localization

# Dotfiles management
setup_dotfiles() {
  export DOTFILES_HOME="$HOME/.dotfiles"
}
setup_dotfiles

# Git aliases and functions
setup_git() {
  alias g='git' gad='git add' gcm='git commit' gph='git push'
  alias gpl='git pull' gpf='git fetch' gfs='git fetch && git status'
  alias gcma='git commit -am "$(_zshrc_git_gen_message)"' gsync='git pull && gcma && git push'
}
setup_git

# Parallel execution aliases
setup_parallel() {
  alias parallel-cluster="parallel -J cluster"
  alias parallel-cluster-order="parallel -k -J cluster"
  alias parallel-local="parallel -J local"
}
setup_parallel

# FZF options
setup_fzf() {
  export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -l -g ""'
  export FZF_DEFAULT_OPTS='--no-height --no-reverse'
  export FZF_CTRL_T_OPTS="--preview '(highlight -O ansi -l {} 2> /dev/null || cat {} || tree -C {}) 2> /dev/null | head -200'"
  export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview'"
}
setup_fzf

# Additional configurations
load_misc_config() {
  local misc_zsh_path="$HOME/.zshrc.d/.misc.zsh"
  [[ -f "$misc_zsh_path" ]] && source "$misc_zsh_path"
  check_exist "$misc_zsh_path"
}
load_misc_config

# Broot setup
setup_broot() {
  local broot_path="$HOME/.config/broot/launcher/bash/br"
  source "$broot_path"
  check_exist "$broot_path"
}
setup_broot

# Tmux setup
setup_tmux() {
  local tmux_path="$HOME/.tmux/plugins/tpm"
  if [[ ! -d "$tmux_path" ]]; then
    git clone https://github.com/tmux-plugins/tpm "$tmux_path"
  fi
  if [[ -z "$SSH_CLIENT" && $SHLVL -eq 1 ]]; then
    tmux attach || tmux new
  fi
}
setup_tmux

# Task-spooler aliases
setup_task_spooler() {
  export TS_SOCK_NET=/var/tmp/socket.net
  export TS_SOCK_CPU=/var/tmp/socket.cpu
  export TS_SOCK_DISK=/var/tmp/socket.disk
  alias tsp-net='TS_SOCKET=$TS_SOCK_NET tsp'
  alias tsp-cpu='TS_SOCKET=$TS_SOCK_CPU tsp'
  alias tsp-disk='TS_SOCKET=$TS_SOCK_DISK tsp'
}
setup_task_spooler

# X11 authority setup
setup_x11_authority() {
  export XAUTHORITY=$HOME/.Xauthority
}
setup_x11_authority

