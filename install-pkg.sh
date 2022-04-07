#!/bin/sh
sudo apt-get -y update || exit
grep -vE "^\s*#" "$1"\
    | tr "\n" " "\
    | xargs sudo apt-get -y install 
