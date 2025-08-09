-- init.lua

-- Windows-specific shell setup
if vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1 or vim.fn.has('win16') == 1 then
  vim.opt.shell = 'powershell.exe'
end

-- General settings
vim.opt.swapfile = false
vim.opt.autoread = true
vim.opt.hidden = true

-- Auto-detect encoding
vim.opt.encoding = 'utf-8'
vim.opt.fileencodings = {'utf-8', 'cp932', 'euc-jp', 'sjis'}

-- Show typing command in the command line
vim.opt.showcmd = true

-- Wrap settings
vim.opt.whichwrap = 'b,s,h,l,<,>,[,]'

-- Appearance settings
vim.opt.number = true
vim.opt.cursorline = true
vim.opt.virtualedit = 'onemore'
vim.opt.showmatch = true
vim.opt.laststatus = 2

-- Command completion
vim.opt.wildmode = {'list', 'longest'}

-- Tab and indent settings
vim.opt.list = true
vim.opt.listchars = 'tab:»-,trail:-,eol:↲,extends:»,precedes:«,nbsp:%'
vim.opt.smartindent = true
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4

-- Search settings
vim.opt.smartcase = true
vim.opt.ignorecase = true
vim.opt.incsearch = true
vim.opt.wrapscan = true
vim.opt.hlsearch = true

-- Color scheme and terminal settings
vim.opt.termguicolors = true

-- Tags settings
vim.opt.tags = 'tags'

-- Auto-generate tags on file write for specific filetypes
vim.api.nvim_create_autocmd('BufWritePost', {
  pattern = {'*.py', '*.c', '*.cpp', '*.h'},
  command = 'silent! !eval "ctags -R -o newtags; mv newtags tags"',
})


-- Auto-generate tags on file write for specific filetypes
vim.api.nvim_create_autocmd('BufWritePost', {
  pattern = {'*.py', '*.c', '*.cpp', '*.h'},
  callback = function()
    vim.fn.system('ctags -R --fields=+n --languages=python,c,c++ --output=tags .')
  end,
})

-- Set leader key
vim.g.mapleader = " "

-- Plugin shortcut mappings
vim.api.nvim_set_keymap('n', '<leader>g', ':Ag<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>f', ':Files ./<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>F', ':Files ~/<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>t', ':Tagbar<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>b', ':Buffers<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>n', ':NERDTreeToggle<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>m', ':MPageToggle<CR>', { noremap = true, silent = true })

-- Terminal settings for Neovim
if vim.fn.has('nvim') == 1 then
  vim.api.nvim_create_autocmd('BufWinEnter', { pattern = 'term://*', command = 'startinsert' })
else
  vim.api.nvim_create_autocmd('WinEnter', { pattern = '*', command = "if &buftype == 'terminal' | normal i | endif" })
end

-- EasyAlign plugin mappings
vim.api.nvim_set_keymap('x', 'ga', '<Plug>(EasyAlign)', { noremap = false })
vim.api.nvim_set_keymap('n', 'ga', '<Plug>(EasyAlign)', { noremap = false })

-- Coc.nvim key mappings
vim.api.nvim_set_keymap('n', 'gd', '<Plug>(coc-definition)', { noremap = false, silent = true })
vim.api.nvim_set_keymap('n', 'gy', '<Plug>(coc-type-definition)', { noremap = false, silent = true })
vim.api.nvim_set_keymap('n', 'gi', '<Plug>(coc-implementation)', { noremap = false, silent = true })
vim.api.nvim_set_keymap('n', 'gr', '<Plug>(coc-references)', { noremap = false, silent = true })

-- Use K to show documentation in preview window
vim.api.nvim_set_keymap('n', 'K', ':lua ShowDocumentation()<CR>', { noremap = true, silent = true })

-- Function to show documentation (with Coc)
function ShowDocumentation()
  if vim.fn['CocAction']('hasProvider', 'hover') == 1 then
    vim.fn['CocActionAsync']('doHover')
  else
    vim.api.nvim_feedkeys('K', 'in', true)
  end
end

-- Clear search highlight with <Esc><Esc>
vim.api.nvim_set_keymap('n', '<Esc><Esc>', ':nohlsearch<CR><Esc>', { noremap = true, silent = true })

-- Better line navigation for wrapped lines
vim.api.nvim_set_keymap('n', 'j', 'gj', { noremap = true })
vim.api.nvim_set_keymap('n', 'k', 'gk', { noremap = true })

-- Inoremap custom mappings for quick escape and pairs
vim.api.nvim_set_keymap('i', 'jj', '<Esc>', { noremap = true, silent = true })

-- Inoremap for pairs and other custom mappings
vim.api.nvim_set_keymap('i', '"', '""<C-o><left>', { noremap = true })
vim.api.nvim_set_keymap('i', '\'', "''<C-o><left>", { noremap = true })
vim.api.nvim_set_keymap('i', '(', '()<C-o><left>', { noremap = true })
vim.api.nvim_set_keymap('i', '[', '[]<C-o><left>', { noremap = true })
vim.api.nvim_set_keymap('i', '{', '{}<C-o><left>', { noremap = true })
vim.api.nvim_set_keymap('i', '<CR>', '{<CR>}<Esc>==O', { noremap = true })

-- Terminal mode mappings
vim.api.nvim_set_keymap('t', '<C-o>', '<C-\\><C-n><C-w>', { noremap = true, silent = true })

-- Set leader key
vim.g.mapleader = " "

-- Python specific settings
vim.api.nvim_create_autocmd({'BufRead', 'BufNewFile'}, {
  pattern = '*.py',
  command = 'set filetype=python'
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'python',
  command = 'setlocal completeopt-=preview'
})

-- General settings
vim.cmd('syntax enable')
vim.opt.visualbell = true

-- Set filetype specific settings
vim.api.nvim_create_autocmd("FileType", {
  pattern = "go",
  command = "setlocal noexpandtab tabstop=2 shiftwidth=2"
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "typescriptreact",
  command = "setlocal expandtab tabstop=2 shiftwidth=2"
})

-- Set colorscheme
vim.cmd("colorscheme codedark")

-- Plugin management using packer.nvim (replace with 'packer' or 'vim-plug' as necessary)
local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()
require('packer').startup(function()
  -- Theme
  use 'tomasiser/vim-code-dark'

  -- NERDTree
  use { 'preservim/nerdtree', config = function() vim.api.nvim_set_keymap('n', '<leader>n', ':NERDTreeToggle<CR>', { noremap = true, silent = true }) end }

  -- MPage
  use 'lacombar/vim-mpage'
  vim.g.mpage_window_prefered_width = 40

  -- Goyo (distraction-free writing)
  use 'junegunn/goyo.vim'

  -- FZF
  use { 'junegunn/fzf', run = ':fzf#install()' }
  use 'junegunn/fzf.vim'

  -- Open browser
  use 'tyru/open-browser.vim'
  vim.g.netrw_nogx = 1
  vim.api.nvim_set_keymap('n', 'gx', '<Plug>(openbrowser-smart-search)', { noremap = true })
  vim.api.nvim_set_keymap('v', 'gx', '<Plug>(openbrowser-smart-search)', { noremap = true })

  -- Tagbar
  use 'preservim/tagbar'
  vim.g.tagbar_position = 'topleft vertical'
  vim.g.rust_use_custom_ctags_defs = 1
  vim.g.tagbar_type_rust = {
    ctagsbin = '/usr/local/bin/ctags',
    ctagstype = 'rust',
    kinds = {
      'n:modules', 's:structures:1', 'i:interfaces', 'c:implementations', 
      'f:functions:1', 'g:enumerations:1', 't:type aliases:1:0', 'v:constants:1:0', 
      'M:macros:1', 'm:fields:1:0', 'e:enum variants:1:0', 'P:methods:1',
    },
    sro = '::',
    kind2scope = {
      n = 'module', s = 'struct', i = 'interface', c = 'implementation', 
      f = 'function', g = 'enum', t = 'typedef', v = 'variable', 
      M = 'macro', m = 'field', e = 'enumerator', P = 'method'
    }
  }

  -- Syntastic
  use 'vim-syntastic/syntastic'
  vim.g.syntastic_always_populate_loc_list = 1
  vim.g.syntastic_auto_loc_list = 1
  vim.g.syntastic_check_on_open = 1
  vim.g.syntastic_check_on_wq = 0
  vim.g.syntastic_sh_checkers = { 'shellcheck' }
  vim.g.syntastic_python_checkers = { 'python', 'flake8', 'mypy' }
  vim.g.syntastic_python_flake8_args = '--ignore="E501"'
  vim.g.syntastic_yaml_checkers = { 'yamllint' }
  vim.g.syntastic_json_checkers = { 'jsonlint' }

  -- Jedi for Python
  use 'davidhalter/jedi-vim'
  vim.g.jedi_usages_command = ""

  -- YAPF for Python formatting
  use { 'google/yapf', rtp = 'plugins/vim' }

  -- HTML5, CSS3, and JS plugins
  use 'othree/html5.vim'
  vim.g.html5_event_handler_attributes_complete = 1
  vim.g.html5_rdfa_attributes_complete = 1
  vim.g.html5_microdata_attributes_complete = 1
  vim.g.html5_aria_attributes_complete = 1

  -- Go language support
  use { 'fatih/vim-go', run = ':GoUpdateBinaries' }
  vim.g.go_fmt_command = "goimports"

  -- CSS3 and JS syntax highlighting
  use 'hail2u/vim-css3-syntax'
  use 'jelera/vim-javascript-syntax'
  use 'mattn/emmet-vim'
  vim.g.user_emmet_leader_key = '<c-t>'

  -- JSX support
  use 'maxmellon/vim-jsx-pretty'

  -- Vimwiki
  use 'vimwiki/vimwiki'
  vim.g.vimwiki_list = {
    { path = '~/wiki/', syntax = 'markdown', index = 'Home', ext = '.md' }
  }

  -- Coc.nvim
  use { 'neoclide/coc.nvim', branch = 'release' }
  vim.api.nvim_set_keymap('x', '<leader>a', '<Plug>(coc-codeaction-selected)', { noremap = false })
  vim.api.nvim_set_keymap('n', '<leader>a', '<Plug>(coc-codeaction-selected)', { noremap = false })
  vim.api.nvim_set_keymap('i', '<silent><expr> <C-l>', 'coc#refresh()', { noremap = true })
  vim.api.nvim_set_keymap('n', '<silent> gd', '<Plug>(coc-definition)', { noremap = false })

  -- UltiSnips and React snippets
  use 'SirVer/ultisnips'
  use 'mlaursen/vim-react-snippets'

  -- Markdown preview
  use({ "iamcco/markdown-preview.nvim", run = "cd app && npm install", setup = function() vim.g.mkdp_filetypes = { "markdown" } end, ft = { "markdown" }, })

  -- Airline
  use 'vim-airline/vim-airline'

  if packer_bootstrap then
    require('packer').sync()
  end
end)

