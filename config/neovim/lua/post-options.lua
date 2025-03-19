local vim = vim
local opt = vim.opt

-- FORMATTING
opt.backspace = 'indent,eol,start'                    -- Smart backspace
opt.tabstop = 4                                     -- Number of spaces a <Tab> in text stands for
opt.shiftwidth = 4                                  -- Number of spaces used for each step of indent
opt.smarttab = true                                       -- a <Tab> is an indent inserts 'shiftwidth' spaces
opt.expandtab = true                                      -- Set <Tab> to spaces in Insert mode
opt.softtabstop = 4                                 -- number of spaces to insert for a <Tab>
opt.autoindent = true                                     -- Auto indentation
opt.smartindent = true                                    -- Do clever auto indentation
opt.wrap = false                                         -- Don't wrap long lines
opt.title = true
opt.titlestring = '%m %F'


-- This is used to foward clipboard to ssh client host
-- https://sw.kovidgoyal.net/kitty/clipboard/
-- NOTE: Use "+y to copy from ssh connection neovim
if os.getenv('SSH_TTY') == nil then
    opt.clipboard = opt.clipboard + 'unnamedplus'                        -- vim uses system clipboard to copy/paste
end

-- Force enable OSC52
if os.getenv('NVIM_FORCE_ENABLE_OSC52') ~= nil then
    vim.g.clipboard = {
      name = 'OSC 52',
      copy = {
        ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
        ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
      },
      paste = {
        ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
        ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
      },
    }
end
