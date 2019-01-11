" general
set fenc=utf-8
set nobackup
set noswapfile
set autoread
set hidden
" show typing command
set showcmd

nnoremap j gj
nnoremap k gk

" looking
" show column no.
set number
" show cursor line
set cursorline

set virtualedit=onemore

set smartindent
" show pair brackets
set showmatch
" show status line
set laststatus=2
" command completion
set wildmode=list:longest


" Tab space
set list listchars=tab:\▸\-
set expandtab
set tabstop=2
set shiftwidth=2


" Search
" Search regardless case
set ignorecase
" Search with case sensitivity
set smartcase
" Search while typing
set incsearch
" Return to the biginning after the last result 
set wrapscan
" hilight search word
set hlsearch
" esc to no hilight 
nmap <Esc><Esc> :nohlsearch<CR><Esc>

" color
syntax enable
set background=dark
colorscheme solarized

