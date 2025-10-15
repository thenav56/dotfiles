-- Set options
vim.opt.encoding = 'utf-8'
vim.opt.clipboard:append('unnamedplus')
vim.opt.foldcolumn = '0'
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.laststatus = 0
vim.opt.compatible = false
vim.opt.list = false
vim.opt.number = false
vim.opt.relativenumber = false
vim.opt.ruler = false
vim.opt.showcmd = false
vim.opt.showmode = false
vim.opt.scrollback = 100000
vim.opt.shell = 'bash'
vim.opt.showtabline = 0
vim.opt.termguicolors = true
vim.opt.undofile = true
vim.opt.undodir = '/tmp/'
vim.opt.undolevels = 1000
vim.opt.undoreload = 1000

-- Key mappings
vim.keymap.set('n', 'q', '<Cmd>quitall!<CR>', { noremap = true })
vim.keymap.set('n', 'i', '<Cmd>quitall!<CR>', { noremap = true })
