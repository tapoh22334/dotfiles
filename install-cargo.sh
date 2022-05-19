#!/bin/sh
grep -vE "^\s*#" "$1"\
    | tr "\n" " "\
    | xargs cargo install 
