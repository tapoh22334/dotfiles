#!/bin/zsh

bindkey "jj" vi-cmd-mode
bindkey '^a' vi-beginning-of-line
bindkey '^e' vi-end-of-line
bindkey '^k' kill-line
bindkey '^u' kill-whole-line

function __zsh_fzf_order_depth() {
    # Sort by depth
    # Add color to lines

    #APPEND=$(\
    #    find . -maxdepth 4 -printf "%d %P\n"\
    #    |sort -n \
    #    |perl -pe 's/^\d+\s//;' \
    #    |xargs -n1 ls --color=always -1d 2>/dev/null \
    #    |fzf --ansi --preview '(tree -Cd ./) 2> /dev/null | head -200'
    #)

    APPEND=$(\
        find . -maxdepth 4 -type d 2>/dev/null \
        | awk '{print length, $1}' \
        | sort -n \
        | cut -d" " -f2- \
        | xargs -n1 ls --color=always -1d 2>/dev/null \
        | fzf --ansi --preview '(tree -Cd ./) 2> /dev/null \
        | head -100'
    )

    BUFFER=${BUFFER}${APPEND}
    CURSOR=${#BUFFER}
}

zle -N __zsh_fzf_order_depth
bindkey '^f' __zsh_fzf_order_depth

bindkey '^R' history-incremental-search-backward
