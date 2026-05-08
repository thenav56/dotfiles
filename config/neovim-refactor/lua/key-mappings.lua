local my_functions = require 'functions'

-- set current file location as pwd
vim.keymap.set('c', 'cd.', 'cd %:p:h')

-- sane jk navigation on wrapped lines
vim.keymap.set('', 'j', 'v:count == 0 ? "gj" : "j"', { silent = true, expr = true })
vim.keymap.set('', 'k', 'v:count == 0 ? "gk" : "k"', { silent = true, expr = true })

-- Navigation
vim.keymap.set('n', '<C-J>', '<C-W><C-J>', { silent = true, remap = false })
vim.keymap.set('n', '<C-K>', '<C-W><C-K>', { silent = true, remap = false })
vim.keymap.set('n', '<C-L>', '<C-W><C-L>', { silent = true, remap = false })
vim.keymap.set('n', '<C-H>', '<C-W><C-H>', { silent = true, remap = false })

-- TODO: Handle url with gf?
-- Open file even if it doesn't exits
vim.keymap.set('n', '<leader>gf', ':e <cfile><CR>', { noremap = true, silent = true })

-- Delete Buffer without impacting splits
vim.keymap.set('n', '<leader>q', ':bp|bd #<CR>', { silent = true })

-- Replace word under cursor with clipboard without overriding current clipboard
-- This can be re-run using `.`
-- https://vim.fandom.com/wiki/Repeat_last_change#Copy_a_line_to_multiple_locations
vim.keymap.set('n', '<leader>p', 'ciw<C-R>0<Esc><CR>', { silent = true })
vim.keymap.set('n', '<leader>P', 'ciW<C-R>0<Esc><CR>', { silent = true })

-- Pass the buffer content
-- -- to bash
vim.keymap.set('n', '<leader>rrr', ':%!bash<CR>', { silent = true })

-- Clear search
vim.keymap.set('n', '<leader><space>', ':nohlsearch<CR>', { silent = true, remap = false })

-- Strip white spaces
vim.keymap.set('n', '<leader>cl', my_functions.TrimWhitespace, { silent = true, remap = false })

-- Zen mode: open current buffer in a new tab, close to exit
vim.keymap.set('n', '<leader>z', function()
  if vim.t.zen_mode then
    vim.cmd('tabclose')
  else
    vim.cmd('tab split')
    vim.t.zen_mode = true
  end
end, { desc = 'Toggle zen mode' })
