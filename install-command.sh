#!/bin/sh -e
sudo apt-get -y update \
&& sudo apt-get -y install $(grep -vE "^\s*#" "$1" | tr "\n" " ")
