#!/bin/zsh

# Catppuccin Mocha color palette for zsh plugins
# This file applies Catppuccin Mocha theme to syntax highlighting and autosuggestions

# Catppuccin Mocha colors
typeset -g CATPPUCCIN_ROSEWATER="rgb(245,224,220)"
typeset -g CATPPUCCIN_FLAMINGO="rgb(242,205,205)"
typeset -g CATPPUCCIN_PINK="rgb(245,194,231)"
typeset -g CATPPUCCIN_MAUVE="rgb(203,166,247)"
typeset -g CATPPUCCIN_RED="rgb(243,139,168)"
typeset -g CATPPUCCIN_MAROON="rgb(235,160,172)"
typeset -g CATPPUCCIN_PEACH="rgb(250,179,135)"
typeset -g CATPPUCCIN_YELLOW="rgb(249,226,175)"
typeset -g CATPPUCCIN_GREEN="rgb(166,227,161)"
typeset -g CATPPUCCIN_TEAL="rgb(148,226,213)"
typeset -g CATPPUCCIN_SKY="rgb(137,220,235)"
typeset -g CATPPUCCIN_SAPPHIRE="rgb(116,199,236)"
typeset -g CATPPUCCIN_BLUE="rgb(137,180,250)"
typeset -g CATPPUCCIN_LAVENDER="rgb(180,190,254)"
typeset -g CATPPUCCIN_TEXT="rgb(205,214,244)"
typeset -g CATPPUCCIN_SUBTEXT1="rgb(186,194,222)"
typeset -g CATPPUCCIN_SUBTEXT0="rgb(166,173,200)"
typeset -g CATPPUCCIN_OVERLAY2="rgb(147,153,178)"
typeset -g CATPPUCCIN_OVERLAY1="rgb(127,132,156)"
typeset -g CATPPUCCIN_OVERLAY0="rgb(108,112,134)"
typeset -g CATPPUCCIN_SURFACE2="rgb(88,91,112)"
typeset -g CATPPUCCIN_SURFACE1="rgb(69,71,90)"
typeset -g CATPPUCCIN_SURFACE0="rgb(49,50,68)"
typeset -g CATPPUCCIN_BASE="rgb(30,30,46)"
typeset -g CATPPUCCIN_MANTLE="rgb(24,24,37)"
typeset -g CATPPUCCIN_CRUST="rgb(17,17,27)"

# Apply Catppuccin colors to zsh-syntax-highlighting
# This will be sourced after zsh-syntax-highlighting is loaded
typeset -gA ZSH_HIGHLIGHT_STYLES

ZSH_HIGHLIGHT_STYLES[default]='fg='$CATPPUCCIN_TEXT
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg='$CATPPUCCIN_RED
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg='$CATPPUCCIN_MAUVE
ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg='$CATPPUCCIN_GREEN',underline'
ZSH_HIGHLIGHT_STYLES[global-alias]='fg='$CATPPUCCIN_GREEN
ZSH_HIGHLIGHT_STYLES[precommand]='fg='$CATPPUCCIN_GREEN',italic'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg='$CATPPUCCIN_PINK
ZSH_HIGHLIGHT_STYLES[autodirectory]='fg='$CATPPUCCIN_PEACH',italic'
ZSH_HIGHLIGHT_STYLES[path]='underline'
ZSH_HIGHLIGHT_STYLES[path_pathseparator]=''
ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]=''
ZSH_HIGHLIGHT_STYLES[globbing]='fg='$CATPPUCCIN_PINK
ZSH_HIGHLIGHT_STYLES[history-expansion]='fg='$CATPPUCCIN_MAUVE
ZSH_HIGHLIGHT_STYLES[command-substitution]='none'
ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]='fg='$CATPPUCCIN_PINK
ZSH_HIGHLIGHT_STYLES[process-substitution]='none'
ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]='fg='$CATPPUCCIN_PINK
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg='$CATPPUCCIN_YELLOW
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg='$CATPPUCCIN_YELLOW
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='none'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument-delimiter]='fg='$CATPPUCCIN_PINK
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg='$CATPPUCCIN_GREEN
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg='$CATPPUCCIN_GREEN
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg='$CATPPUCCIN_GREEN
ZSH_HIGHLIGHT_STYLES[rc-quote]='fg='$CATPPUCCIN_TEAL
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg='$CATPPUCCIN_TEAL
ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]='fg='$CATPPUCCIN_TEAL
ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]='fg='$CATPPUCCIN_TEAL
ZSH_HIGHLIGHT_STYLES[assign]='fg='$CATPPUCCIN_TEXT
ZSH_HIGHLIGHT_STYLES[redirection]='fg='$CATPPUCCIN_PINK
ZSH_HIGHLIGHT_STYLES[comment]='fg='$CATPPUCCIN_OVERLAY0',italic'
ZSH_HIGHLIGHT_STYLES[named-fd]='fg='$CATPPUCCIN_TEXT
ZSH_HIGHLIGHT_STYLES[numeric-fd]='fg='$CATPPUCCIN_TEXT
ZSH_HIGHLIGHT_STYLES[arg0]='none'
ZSH_HIGHLIGHT_STYLES[bracket-error]='fg='$CATPPUCCIN_RED',bold'
ZSH_HIGHLIGHT_STYLES[bracket-level-1]='fg='$CATPPUCCIN_OVERLAY2
ZSH_HIGHLIGHT_STYLES[bracket-level-2]='fg='$CATPPUCCIN_OVERLAY2
ZSH_HIGHLIGHT_STYLES[bracket-level-3]='fg='$CATPPUCCIN_OVERLAY2
ZSH_HIGHLIGHT_STYLES[bracket-level-4]='fg='$CATPPUCCIN_OVERLAY2
ZSH_HIGHLIGHT_STYLES[bracket-level-5]='fg='$CATPPUCCIN_OVERLAY2
ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]='fg='$CATPPUCCIN_TEXT',standout'
ZSH_HIGHLIGHT_STYLES[builtin]='none'
ZSH_HIGHLIGHT_STYLES[command]='none'
ZSH_HIGHLIGHT_STYLES[function]='none'
ZSH_HIGHLIGHT_STYLES[alias]='none'
ZSH_HIGHLIGHT_STYLES[suffix-alias]='none'
ZSH_HIGHLIGHT_STYLES[global-alias]='none'

# Configure zsh-autosuggestions colors (Catppuccin Mocha)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#585b70,italic"  # surface2 color for subtle suggestions

# Configure fast-syntax-highlighting (minimal colors)
typeset -gA FAST_HIGHLIGHT_STYLES
FAST_HIGHLIGHT_STYLES[default]='none'
FAST_HIGHLIGHT_STYLES[unknown-token]='fg=red,bold'
FAST_HIGHLIGHT_STYLES[reserved-word]='fg=yellow'
FAST_HIGHLIGHT_STYLES[alias]='none'
FAST_HIGHLIGHT_STYLES[suffix-alias]='none'
FAST_HIGHLIGHT_STYLES[builtin]='none'
FAST_HIGHLIGHT_STYLES[function]='none'
FAST_HIGHLIGHT_STYLES[command]='none'
FAST_HIGHLIGHT_STYLES[precommand]='none'
FAST_HIGHLIGHT_STYLES[commandseparator]='none'
FAST_HIGHLIGHT_STYLES[hashed-command]='none'
FAST_HIGHLIGHT_STYLES[path]='underline'
FAST_HIGHLIGHT_STYLES[path-to-dir]='underline'
FAST_HIGHLIGHT_STYLES[globbing]='fg=blue'
FAST_HIGHLIGHT_STYLES[history-expansion]='fg=blue,bold'
FAST_HIGHLIGHT_STYLES[single-hyphen-option]='fg=yellow'
FAST_HIGHLIGHT_STYLES[double-hyphen-option]='fg=yellow'
FAST_HIGHLIGHT_STYLES[back-quoted-argument]='none'
FAST_HIGHLIGHT_STYLES[single-quoted-argument]='fg=green'
FAST_HIGHLIGHT_STYLES[double-quoted-argument]='fg=green'
FAST_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=green'
FAST_HIGHLIGHT_STYLES[back-or-dollar-double-quoted-argument]='fg=cyan'
FAST_HIGHLIGHT_STYLES[back-dollar-quoted-argument]='fg=cyan'
FAST_HIGHLIGHT_STYLES[assign]='none'
FAST_HIGHLIGHT_STYLES[redirection]='none'
FAST_HIGHLIGHT_STYLES[comment]='fg=8'
FAST_HIGHLIGHT_STYLES[variable]='none'
FAST_HIGHLIGHT_STYLES[mathvar]='fg=blue,bold'
FAST_HIGHLIGHT_STYLES[mathnum]='fg=magenta'
FAST_HIGHLIGHT_STYLES[matherr]='fg=red'
FAST_HIGHLIGHT_STYLES[assign-array-bracket]='none'
FAST_HIGHLIGHT_STYLES[for-loop-variable]='none'
FAST_HIGHLIGHT_STYLES[for-loop-number]='fg=magenta'
FAST_HIGHLIGHT_STYLES[for-loop-operator]='fg=yellow'
FAST_HIGHLIGHT_STYLES[for-loop-separator]='fg=yellow,bold'
FAST_HIGHLIGHT_STYLES[exec-descriptor]='fg=yellow,bold'
FAST_HIGHLIGHT_STYLES[here-string-tri]='fg=yellow'
FAST_HIGHLIGHT_STYLES[here-string-text]='fg=green'
FAST_HIGHLIGHT_STYLES[here-string-var]='fg=cyan,bg=black'
FAST_HIGHLIGHT_STYLES[secondary]=none
FAST_HIGHLIGHT_STYLES[case-input]='fg=green'
FAST_HIGHLIGHT_STYLES[case-parentheses]='fg=yellow'
FAST_HIGHLIGHT_STYLES[case-condition]='bg=blue'

# Enable completion menu colors
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:*:*:*:descriptions' format '%F{#cba6f7}-- %d --%f'  # mauve
zstyle ':completion:*:*:*:*:corrections' format '%F{#f9e2af}-- %d (errors: %e) --%f'  # yellow
zstyle ':completion:*:messages' format ' %F{#cba6f7}-- %d --%f'  # mauve
zstyle ':completion:*:warnings' format ' %F{#f38ba8}-- no matches found --%f'  # red
zstyle ':completion:*' group-name ''

# Minimal LS_COLORS - only essentials with bright colors
# di=directory(bright blue), ln=symlink(bright cyan), ex=executable(bright green)
export LS_COLORS='di=01;34:ln=01;36:ex=01;32'
