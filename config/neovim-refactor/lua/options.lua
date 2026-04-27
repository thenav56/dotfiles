require('vim._core.ui2').enable({})

-- Leaders
vim.g.mapleader = ","
vim.g.maplocalleader = "\\"
-- opt.cmdheight = 2

-- UI / colors
vim.opt.number = true
-- vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.opt.fillchars:append({ vert = " ", fold = " " })

-- Search (keep only real overrides)
vim.opt.smartcase = true
vim.opt.ignorecase = true

-- Splits
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Mouse
vim.opt.mouse = "a"

-- UI behavior
vim.opt.showmatch = true
vim.opt.shortmess:append("filmnrxoOtT")

-- Scrolling
vim.opt.scrolloff = 5
vim.opt.sidescrolloff = 5

-- Which-key style navigation behavior
vim.opt.whichwrap = "b,s,h,l,<,>,[,]"

-- wildmenu (commandline Completion)
vim.opt.wildmode = "lastused,full"
vim.opt.wildoptions = "pum,fuzzy"
vim.opt.wildignorecase = true
vim.opt.wildignore:append({
  "*/.git/*",
  "*/.hg/*",
  "*/.svn/*",
  "*/.yardoc/*",
  "*/js-build/*",
  "*/node_modules/*",
  "*.exe",
  "*.so",
  "*.dat",
  "*.o",
  "*.obj",
  "*.pyc",
})

-- Whitespace visualization
vim.opt.list = true
vim.opt.listchars = {
  tab = "› ",
  trail = "•",
  extends = "#",
  nbsp = ".",
}

-- Word behavior
vim.opt.iskeyword:remove(".") -- '.' no longer part of words

-- Buffers / editing behavior
vim.opt.backup = true
vim.opt.undofile = true
-- Directories
local data = vim.fn.stdpath("data")
vim.opt.undodir = { data .. "/undo", "/tmp" }
vim.opt.backupdir = { data .. "/backup", "/tmp" }
vim.opt.directory = { data .. "/swap", "/tmp" }
