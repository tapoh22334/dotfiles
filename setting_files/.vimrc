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

"colorscheme solarized
colorscheme codedark

""""""""""""""""""""""""""""""""""""""""""""
let s:dein_dir = '~/.cache/dein'
let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'

if &runtimepath !~# '/dein.vim'
  if !isdirectory(s:dein_repo_dir)
    execute '!git clone https://github.com/Shougo/dein.vim' s:dein_repo_dir
  endif
  execute 'set runtimepath^=' . fnamemodify(s:dein_repo_dir, ':p')
endif

if dein#load_state('~/.cache/dein')
  call dein#begin('~/.cache/dein')

  let g:rc_dir    = '~/.vim/rc'
  let s:toml      = g:rc_dir . '/dein.toml'
  let s:lazy_toml = g:rc_dir . '/dein_lazy.toml'

  call dein#load_toml(s:toml,       {'lazy': 0})
  call dein#load_toml(s:lazy_toml,  {'lazy': 1})

  call dein#end()
  call dein#save_state()
endif

if dein#check_install()
  call dein#install()
endif

