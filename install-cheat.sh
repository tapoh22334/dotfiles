#!/bin/bash

cheat_root="$( cd "$( dirname "$0" )" && pwd )/cheat"
ln -s "$cheat_root" "${HOME}/.local/share/navi/cheats/"

