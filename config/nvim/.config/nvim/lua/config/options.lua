-- options.lua - Neovim settings

-- General settings
vim.opt.swapfile = false
vim.opt.autoread = true
vim.opt.hidden = true

-- Encoding
vim.opt.encoding = 'utf-8'
vim.opt.fileencodings = {'utf-8', 'cp932', 'euc-jp', 'sjis'}

-- Show typing command
vim.opt.showcmd = true

-- Wrap settings
vim.opt.whichwrap = 'b,s,h,l,<,>,[,]'

-- Appearance
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

-- Color scheme and terminal
vim.opt.termguicolors = true

-- Tags
vim.opt.tags = 'tags'

-- Syntax
vim.cmd('syntax enable')
vim.opt.visualbell = true

-- Localization
vim.env.LANG = 'en_US.UTF-8'
vim.env.LSCOLORS = 'gxfxxxxxcxxxxxxxxxgxgx'

-- File type specific settings
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'go',
  command = 'setlocal noexpandtab tabstop=2 shiftwidth=2'
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'typescriptreact',
  command = 'setlocal expandtab tabstop=2 shiftwidth=2'
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'python',
  command = 'setlocal completeopt-=preview'
})

-- Python filetype
vim.api.nvim_create_autocmd({'BufRead', 'BufNewFile'}, {
  pattern = '*.py',
  command = 'set filetype=python'
})

-- Windows-specific shell setup
if vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1 or vim.fn.has('win16') == 1 then
  vim.opt.shell = 'powershell.exe'
end
