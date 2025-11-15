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

# Add file path highlighting via LS_COLORS (for Catppuccin Mocha)
export LS_COLORS='rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.zst=01;31:*.tzst=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.wim=01;31:*.swm=01;31:*.dwm=01;31:*.esd=01;31:*.jpg=01;35:*.jpeg=01;35:*.mjpg=01;35:*.mjpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.oga=00;36:*.opus=00;36:*.spx=00;36:*.xspf=00;36:'
