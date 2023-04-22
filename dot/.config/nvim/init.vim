" Vimrc
"
" general
" set nobackup
set noswapfile
set autoread
set hidden

" Auto detecting encode. Jis type encoding must be specified head of encode list
set encoding=utf-8
set fileencodings=utf-8,cp932,euc-jp,sjis

" show typing command
set showcmd

set whichwrap=b,s,h,l,<,>,[,]

" looking
set number
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
set list
set listchars=tab:»-,trail:-,eol:↲,extends:»,precedes:«,nbsp:%
set expandtab
set tabstop=4
set shiftwidth=4

" Search
" Search with case sensitivity
set smartcase
set ignorecase
" Search while typing
set incsearch
" Return to the biginning after the last result 
set wrapscan
" hilight search word
set hlsearch

"colorscheme solarized
set t_Co=256
set t_ut=
colorscheme codedark

" tag
set tags
au BufWritePost *.py,*.c,*.cpp,*.h silent! !eval 'ctags -R -o newtags; mv newtags tags' &

"" remaps 

""" plugin shortcut
nnoremap <space>g :Ag<CR>
nnoremap <space>f :Files ./<CR>
nnoremap <space>F :Files ~/<CR>
nnoremap <space>t :Tagbar<CR>
nnoremap <space>b :Buffers<CR>
nnoremap <Space>n :NERDTreeToggle<CR>
nnoremap <Space>m :MPageToggle<CR>
nnoremap <Space><Space> :
nnoremap <silent> <C-w>" :split \| wincmd j \| resize 20 \| terminal<CR>
nnoremap <silent> <C-w>' :vsplit \| wincmd l \| terminal<CR>

xmap ga <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)

"""
nmap <Esc><Esc> :nohlsearch<CR><Esc>
nnoremap j gj
nnoremap k gk
inoremap <silent> jj <ESC>
inoremap <C-l> <Up><End><CR>
inoremap " ""🥕<C-o>2<left>
inoremap ' ''🥕<C-o>2<left>
inoremap ( ()🥕<C-o>2<left>
inoremap () ()
inoremap [ []🥕<C-o>2<left>
inoremap [] []
inoremap { {}🥕<C-o>2<left>
inoremap {<CR> {<CR>}🥕<ESC>==O
inoremap {} {}
inoremap <> <>🥕<C-o>2<left>
inoremap <C-k> <ESC>/🥕<CR>s

""" terminal settin """
" nvim not opens terminal in current dir
if has('nvim')
  autocmd BufWinEnter,WinEnter term://* startinsert
else
  autocmd WinEnter * if &buftype ==# 'terminal' | normal i | endif
endif

"""" move window in order
tnoremap <C-o> <C-\><C-n><C-w>

"""""""""""" Plugin python """""""""""""
autocmd BufRead,BufNewFile *.py setfiletype python
autocmd FileType python setlocal completeopt-=preview

syntax enable
set visualbell t_vb=

call plug#begin()
Plug 'tomasiser/vim-code-dark', {'do':
    \'mkdir -p ~/.config/nvim/colors/; rsync -a colors/ ~/.config/nvim/colors/' }
Plug 'preservim/nerdtree', { 'on': 'NERDTreeToggle' }

Plug 'lacombar/vim-mpage'
let g:mpage_window_prefered_width = 40

Plug 'junegunn/goyo.vim'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" CTRL-A CTRL-Q to select all and build quickfix list
function! s:build_quickfix_list(lines)
  call setqflist(map(copy(a:lines), '{ "filename": v:val }'))
  copen
  cc
endfunction

let g:fzf_action = {
  \ 'ctrl-q': function('s:build_quickfix_list'),
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }

let $FZF_DEFAULT_OPTS = '--bind ctrl-a:select-all'

Plug 'dhruvasagar/vim-table-mode'
Plug 'vim-scripts/DoxygenToolkit.vim'
Plug 'junegunn/vim-easy-align'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-fugitive'
Plug 'mg979/vim-visual-multi'

Plug 'tyru/open-browser.vim'
let g:openbrowser_browser_commands = [
       \ {'name': '/mnt/c/Program Files (x86)/Google/Chrome/Application/chrome.exe',
       \  'args': ['{browser}', '{uri}']} ]
" command! OpenBrowserCurrent execute "OpenBrowser" expand("%")


Plug 'preservim/tagbar'
let g:tagbar_position = 'topleft vertical'
let g:rust_use_custom_ctags_defs = 1
let g:tagbar_type_rust = {
  \ 'ctagsbin' : '/usr/local/bin/ctags',
  \ 'ctagstype' : 'rust',
  \ 'kinds' : [
      \ 'n:modules',
      \ 's:structures:1',
      \ 'i:interfaces',
      \ 'c:implementations',
      \ 'f:functions:1',
      \ 'g:enumerations:1',
      \ 't:type aliases:1:0',
      \ 'v:constants:1:0',
      \ 'M:macros:1',
      \ 'm:fields:1:0',
      \ 'e:enum variants:1:0',
      \ 'P:methods:1',
  \ ],
  \ 'sro': '::',
  \ 'kind2scope' : {
      \ 'n': 'module',
      \ 's': 'struct',
      \ 'i': 'interface',
      \ 'c': 'implementation',
      \ 'f': 'function',
      \ 'g': 'enum',
      \ 't': 'typedef',
      \ 'v': 'variable',
      \ 'M': 'macro',
      \ 'm': 'field',
      \ 'e': 'enumerator',
      \ 'P': 'method',
  \ },
\ }

Plug 'vim-syntastic/syntastic'
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

let g:syntastic_sh_checkers = ['shellcheck']
let g:syntastic_python_checkers = ['python', 'flake8', 'mypy']
let g:syntastic_yaml_checkers = ['yamllint']
let g:syntastic_json_checkers = ['jsonlint']

Plug 'davidhalter/jedi-vim'

Plug 'google/yapf', {'rtp': 'plugins/vim'}


Plug 'othree/html5.vim', {'for': ['html','vue']}
let g:html5_event_handler_attributes_complete = 1
let g:html5_rdfa_attributes_complete = 1
let g:html5_microdata_attributes_complete = 1
let g:html5_aria_attributes_complete = 1

Plug 'hail2u/vim-css3-syntax', {'for': ['css','scss','sass']}
Plug 'jelera/vim-javascript-syntax', {'for': ['javascript']}
Plug 'mattn/emmet-vim', {'for': ['html']}
"Plug 'rust-lang/rust.vim', {'for': ['rust']}
"syntax enable
"filetype plugin indent on

Plug 'vimwiki/vimwiki'
let g:vimwiki_list = [{'path': '~/wiki/',
                      \ 'syntax': 'markdown',
                      \ 'index': 'Home',
                      \ 'ext': '.md'}]

Plug 'neoclide/coc.nvim', {'branch': 'release'}

call plug#end()

