#!/bin/sh

_PKGS=$(cat << EOS
## Utils
zsh
tmux
git
moreutils
tree
jq
EOS
)
PKGS=$( echo $_PKGS | grep -vE "^\s*#" | tr "\n" " " )

## Search
_PKGS_APT=$(cat << EOS
silversearcher-ag
EOS
)
PKGS_APT=$( echo $_PKGS_APT | grep -vE "^\s*#" | tr "\n" " " )

_PKGS_BREW=$(cat <<EOS
ag
EOS
)
PKGS_BREW=$( echo $_PKGS_BREW | grep -vE "^\s*#" | tr "\n" " " )


if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  sudo apt-get -y update || exit
  sudo apt-get -y install $PKGS $PKGS_APT

elif [[ "$OSTYPE" == "darwin"* ]]; then
  brew update || exit
  brew install $PKGS $PKGS_BREW

else
  echo "Unknown OS"
fi

