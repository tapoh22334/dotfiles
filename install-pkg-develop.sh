#!/bin/sh

## Network
PKGS=$(echo $PKGS; cat << EOS

arp-scan

EOS)

## Editor
PKGS=$(echo $PKGS; cat << EOS
neovim
EOS)

## Shell-script
PKGS=$(echo $PKGS; cat << EOS
shellcheck
EOS)

## C/C++
PKGS=$(echo $PKGS; cat << EOS
ctags
cmake
gdb
clang-format
EOS)

## Ruby
PKGS=$(echo $PKGS; cat << EOS
ruby
EOS)

PKGS=$(echo $PKGS | grep -vE "^\s*#" | tr "\n" " " )

## Search
_PKGS_APT=$(cat << EOS
EOS
)
PKGS_APT=$( echo $_PKGS_APT | grep -vE "^\s*#" | tr "\n" " " )

_PKGS_BREW=$(cat <<EOS
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

