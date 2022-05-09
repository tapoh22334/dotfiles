" general
"
"set nobackup
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
inoremap <C-l> <Up><End><CR>
"inoremap " ""<`0`><C-o>6<left>
"inoremap ' ''<`0`><C-o>6<left>
"inoremap ( ()<`0`><C-o>6<left>
"inoremap [ []<`0`><C-o>6<left>
"inoremap { {}<`0`><C-o>6<left>
"inoremap {<CR> {<CR>}<ESC>O
"inoremap {;<CR> {<CR>};<ESC>O

""" terminal settin """
" nvim not opens terminal in current dir
if has('nvim')
  autocmd BufWinEnter,WinEnter term://* startinsert
else
  autocmd WinEnter * if &buftype ==# 'terminal' | normal i | endif
endif

"""" move window in order
tnoremap <C-o> <C-\><C-n><C-w>

"""""""""""" OpenBrowset """""""""""""""
let g:openbrowser_browser_commands = [
       \ {'name': '/mnt/c/Program Files (x86)/Google/Chrome/Application/chrome.exe',
       \  'args': ['{browser}', '{uri}']} ]
" command! OpenBrowserCurrent execute "OpenBrowser" expand("%")

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

Plug 'dhruvasagar/vim-table-mode'
Plug 'vim-scripts/DoxygenToolkit.vim'
Plug 'junegunn/vim-easy-align'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-fugitive'
Plug 'mg979/vim-visual-multi'

Plug 'preservim/tagbar'
let g:tagbar_position = 'topleft vertical'

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
Plug 'rust-lang/rust.vim', {'for': ['rust']}

Plug 'vimwiki/vimwiki'
let g:vimwiki_list = [{'path': '~/wiki/',
                      \ 'syntax': 'markdown',
                      \ 'index': 'Home',
                      \ 'ext': '.md'}]

"" Make sure you use single quotes
"function! BuildYCM(info)
"  " info is a dictionary with 3 fields
"  " - name:   name of the plugin
"  " - status: 'installed', 'updated', or 'unchanged'
"  " - force:  set on PlugInstall! or PlugUpdate!
"  if a:info.status == 'installed' || a:info.force
"    "!./install.py
"    !python3 install.py --clangd-completer --rust-complete
"  endif
"endfunction
"Plug 'ycm-core/YouCompleteMe', { 'do': function('BuildYCM') }

call plug#end()
