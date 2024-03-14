local g = vim.g
local opt = vim.opt

g.mapleader = ','
g.maplocalleader = '\\'

-- https://github.com/neovim/neovim/issues/2437#issuecomment-522236703
g.python_host_prog = '/usr/bin/python2'
g.python3_host_prog = '/usr/bin/python3'

opt.termguicolors = true
opt.synmaxcol = 250                                 -- syntax highlighting line size limit
opt.compatible = false                                    -- Don't behave very Vi compatible
opt.encoding = 'UTF-8'                                -- Set character encoding
-- opt.lazyredraw = true                                      -- Don't draw while executing macros
opt.hidden = true                                          -- Don't unload a buffer when no longer show in window
opt.foldenable = false                                    -- Set to display all folds open
opt.remap = true                                          -- Recognize mappings in mapped keys
opt.spell = false                                        -- Disable spell correction
opt.scroll = 9                                      -- Number of lines to scroll for Ctrl-U and Ctrl-D
opt.scrolloff = 5                                   -- Minimal number of screen lines to keep above/below the cursor.
opt.scrolljump = 5                                  -- Lines to scroll when cursor leaves screen
opt.mousehide = true                                      -- Hide mouse while typing
opt.mouse = 'a'                                       -- Enable mouse for all modes
opt.incsearch = true                                      -- Show match for partly typed search command
opt.hlsearch = true                                       -- Highlight search
opt.smartcase = true                                       -- Uses case insensitive search
opt.ignorecase = true                                       -- Uses case insensitive search
opt.splitbelow = true                                     -- A new window is put below the current one
opt.splitright = true                                     -- A new window is put right of the current one
opt.history = 100                                   -- Set number of command line history remembered
opt.updatetime = 4000                               -- Time in ms after which swap will be updated
opt.updatecount = 200                               -- Number of characters typed to cause a swap file update
opt.undofile = true                                        -- Automatically save and restore undo history
opt.undolevels = 1000                               -- Over 1000 levels of undo
opt.undoreload = 10000                              -- Maximum number lines to save for undo on a buffer reload
opt.backup = true                                         -- Enable backup
opt.showmatch = true                                      -- When inserting bracket, briefly jump to its match
opt.number = true                                         -- Show line number for each line
opt.cursorline = true                                     -- Show cursor line
opt.fillchars = opt.fillchars + 'vert: ,fold: '                             -- Remove ugly | in split
opt.laststatus = 2
opt.shortmess = 'filmnrxoOtT'                       -- Show short message to avoid hit-enter
opt.whichwrap = 'b,s,h,l,<,>,[,]'                   -- Backspace and cursor keys wrap too
opt.viewoptions = 'folds,options,cursor,unix,slash' -- Better Unix / Windows compatibility
opt.iskeyword = opt.iskeyword - '.'                                  -- '.' is an end of word designator
opt.list = true                                            -- Useful to see difference between tab and space
opt.listchars = 'tab:› ,trail:•,extends:#,nbsp:.'    -- Highlight problematic whitespace
opt.wildmode = 'longest,list,full'
opt.wildmenu = true
opt.wildignorecase = true                                 -- Ignore case when completing file names
-- List of file patterns ignored while expanding wildcards
opt.wildignore = opt.wildignore + '*/.git/*,*/.hg/*,*/.svn/*,*/.yardoc/*,*/js-build/*,*/node_modules/*,*.exe,*.so,*.dat,*.o,*.obj,*.pyc'

-- Directories
opt.undodir = '~/.local/share/nvim/undo,/tmp'                     -- Directory for vim undo
opt.backupdir = '~/.local/share/nvim/backup,/tmp'                 -- Set backup dir
opt.directory = '~/.local/share/nvim/swap,/tmp'                   -- Directory for vim swap

-- Other configs are at ./post-options.lua
