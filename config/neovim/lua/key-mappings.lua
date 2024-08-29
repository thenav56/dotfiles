local my_functions = require 'functions'
local map = vim.keymap.set

-- set current file location as pwd
map('c', 'cd.', 'cd %:p:h')

-- open init.lua
map('n', '<leader>e', ':e $MYVIMRC<CR>', { silent = true })


-- sane jk navigation on wrapped lines
map('', 'j', 'v:count == 0 ? "gj" : "j"', { silent = true, expr = true })
map('', 'k', 'v:count == 0 ? "gk" : "k"', { silent = true, expr = true })

-- CHAD
-- NOTE: <tab> == ctrl-i (opposite to ctrl+o), so use <c-tab> instead
-- https://github.com/neovim/neovim/issues/5916
map('', '<leader><tab>', ':CHADopen<CR>', { silent = true, remap = false })
-- map('', '<c-tab>', ':CHADopen<CR>', { silent = true, remap = false })

-- FZF
map('n', '<leader>bs', ':History<CR>', { silent = true })

-- Navigation
map('n', '<C-J>', '<C-W><C-J>', { silent = true, remap = false })
map('n', '<C-K>', '<C-W><C-K>', { silent = true, remap = false })
map('n', '<C-L>', '<C-W><C-L>', { silent = true, remap = false })
map('n', '<C-H>', '<C-W><C-H>', { silent = true, remap = false })

-- Delete Buffer without impacting splits
map('n', '<leader>q', ':bp|bd #<CR>', { silent = true })

-- Replace word under cursor with clipboard without overriding current clipboard
-- This can be re-run using `.`
-- https://vim.fandom.com/wiki/Repeat_last_change#Copy_a_line_to_multiple_locations
map('n', '<leader>p', 'ciw<C-R>0<Esc><CR>', { silent = true })
map('n', '<leader>P', 'ciW<C-R>0<Esc><CR>', { silent = true })

-- Pass the buffer content
-- -- to bash
map('n', '<leader>rrr', ':%!bash<CR>', { silent = true })

-- Clear search
map('n', '<leader><space>', ':nohlsearch<CR>', { silent = true, remap = false })

-- Strip white spaces
map('n', '<leader>cl', my_functions.TrimWhitespace, { silent = true, remap = false })

-- Suggest correctly spelled words (Using spelunker)
map('n', '<leader>ss', ':call spelunker#correct_from_list()<CR>', { silent = true })

-- Trouble
map("n", "<leader>xx", ":Trouble diagnostics toggle<CR>")  -- Diagnostics (Trouble)
map("n", "<leader>xd", ":Trouble diagnostics toggle filter.buf=0<CR>")  -- Buffer Diagnostics (Trouble)
map("n", "<leader>xq", ":Trouble qflist toggle<CR>")  -- Quickfix List (Trouble)
map("n", "<leader>xl", ":Trouble loclist toggle<CR>")  -- Location List (Trouble)
map("n", "<leader>xs", ":Trouble symbols toggle focus=false<CR>")  -- Symbols (Trouble)
map("n", "gR", ":Trouble lsp toggle focus=false win.position=right<CR>")  -- LSP Definitions / references / ... (Trouble)
-- Move to next/previous troubles
map("n", "[t", function() require("trouble").next({skip_groups = true, jump = true}) end)
map("n", "]t", function() require("trouble").previous({skip_groups = true, jump = true}) end)
