#!/bin/zsh

function __zsh_fzf_order_depth() {
    # Sort by depth
    # Add color to lines

    BUFFER=${BUFFER}$(\
        find . -maxdepth 4 -printf "%d %P\n"\
        |sort -n \
        |perl -pe 's/^\d+\s//;' \
        |xargs -n1 ls --color=always -1d 2>/dev/null \
        |fzf --ansi
    )

    CURSOR=${#BUFFER}
}

zle -N __zsh_fzf_order_depth
bindkey '^f' __zsh_fzf_order_depth

bindkey '^R' history-incremental-search-backward
