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
nnoremap <space>g :Denite grep<CR>
nnoremap <space>f :Files ./<CR>
nnoremap <space>F :Files ~/<CR>
nnoremap <space>b :Denite buffer<CR>
nmap <C-n> :NERDTreeToggle<CR>

xmap ga <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)

nnoremap <Space><Space> :call deoplete#toggle()<CR>

""" 
nmap <Esc><Esc> :nohlsearch<CR><Esc>
nnoremap j gj
nnoremap k gk
inoremap <C-l> <Up><End><CR>
inoremap " ""<`0`><C-o>6<left>
inoremap ' ''<`0`><C-o>6<left>
inoremap ( ()<`0`><C-o>6<left>
inoremap [ []<`0`><C-o>6<left>
inoremap { {}<`0`><C-o>6<left>
inoremap {<CR> {<CR>}<ESC>O
inoremap {;<CR> {<CR>};<ESC>O

""" terminal settin """
if has('nvim')
  " Neovim 用
  autocmd WinEnter * if &buftype ==# 'terminal' | startinsert | endif
else
  " Vim 用
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

"""""""""""" Denite """"""""""""""""""""""
" Define mappings
autocmd FileType denite call s:denite_my_settings()
function! s:denite_my_settings() abort
  nnoremap <silent><buffer><expr> <CR>
  \ denite#do_map('do_action')
  nnoremap <silent><buffer><expr> d
  \ denite#do_map('do_action', 'delete')
  nnoremap <silent><buffer><expr> p
  \ denite#do_map('do_action', 'preview')
  nnoremap <silent><buffer><expr> q
  \ denite#do_map('quit')
  nnoremap <silent><buffer><expr> i
  \ denite#do_map('open_filter_buffer')
  nnoremap <silent><buffer><expr> <Space>
  \ denite#do_map('toggle_select').'j'
endfunction

"""""""""""" Dein """"""""""""""""""""""""""
let s:dein_dir = expand('~/.cache/dein')
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
""""""""""""""""""""""""""""""""""""""""""""

syntax enable
set visualbell t_vb=
