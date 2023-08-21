local map = vim.keymap.set

-- set current file location as pwd
map('c', 'cd.', 'cd %:p:h')

-- open init.lua
map('n', '<leader>e', ':e $MYVIMRC<CR>', { silent = true })


-- sane jk navigation on wrapped lines
map('', 'j', 'v:count == 0 ? "gj" : "j"', { silent = true, expr = true })
map('', 'k', 'v:count == 0 ? "gk" : "k"', { silent = true, expr = true })

-- CHAD
map('', '<tab>', ':CHADopen<CR>', { silent = true, remap = false })

-- FZF
map('n', ';', ':Buffers<CR>', { silent = true })
map('n', '<C-P>', ':Files<CR>', { silent = true })
map('n', '<leader>bs', ':History<CR>', { silent = true })

-- Navigation
map('n', '<C-J>', '<C-W><C-J>', { silent = true, remap = false })
map('n', '<C-K>', '<C-W><C-K>', { silent = true, remap = false })
map('n', '<C-L>', '<C-W><C-L>', { silent = true, remap = false })
map('n', '<C-H>', '<C-W><C-H>', { silent = true, remap = false })

-- Delete Buffer withouting impacting splits
map('n', '<leader>q', ':bdelete<CR>', { silent = true })

-- Clear search
map('n', '<leader><space>', ':nohlsearch<CR>', { silent = true, remap = false })

-- Full text search
map('n', '<leader>fa', ':Rg<CR>', { silent = true, remap = false })
