-- keymaps.lua - General keymaps (non-plugin specific)

-- Clear search highlight
vim.keymap.set('n', '<Esc><Esc>', ':nohlsearch<CR><Esc>', { noremap = true, silent = true })

-- Better line navigation for wrapped lines
vim.keymap.set('n', 'j', 'gj', { noremap = true })
vim.keymap.set('n', 'k', 'gk', { noremap = true })

vim.keymap.set('n', '<Tab>', ':bnext<CR>', { silent = true })
vim.keymap.set('n', '<S-Tab>', ':bprevious<CR>', { silent = true })

-- Quick escape from insert mode
vim.keymap.set('i', 'jj', '<Esc>', { noremap = true, silent = true })

-- Auto-pairs are handled by nvim-autopairs plugin

-- Terminal mode mappings
vim.keymap.set('t', '<C-o>', '<C-\\><C-n><C-w>', { noremap = true, silent = true })

-- Terminal autocommands
if vim.fn.has('nvim') == 1 then
    vim.api.nvim_create_autocmd('BufWinEnter', {
        pattern = 'term://*',
        command = 'startinsert'
    })
else
    vim.api.nvim_create_autocmd('WinEnter', {
        pattern = '*',
        command = "if &buftype == 'terminal' | normal i | endif"
    })
end
