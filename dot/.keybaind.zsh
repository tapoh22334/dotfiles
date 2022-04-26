#!/bin/zsh

bindkey '^a' vi-beginning-of-line
bindkey '^e' vi-end-of-line
bindkey '^k' kill-line
bindkey '^u' kill-whole-line

function __zsh_fzf_order_depth() {
    # Sort by depth
    # Add color to lines

    #find ./ -maxdepth 1 -printf "%P\n" \
    #    |xargs -n1 ls --color=always -1d 2>/dev/null \
    #    | fzf --ansi

    BUFFER=${BUFFER}$(\
        find . -maxdepth 4 -printf "%d %P\n"\
        |sort -n \
        |perl -pe 's/^\d+\s//;' \
        |xargs -n1 ls --color=always -1d 2>/dev/null \
        |fzf --ansi --preview '(tree -Cd ./) 2> /dev/null | head -200'
    )

    #CURSOR=${#BUFFER}
}

zle -N __zsh_fzf_order_depth
bindkey '^f' __zsh_fzf_order_depth

bindkey '^R' history-incremental-search-backward
