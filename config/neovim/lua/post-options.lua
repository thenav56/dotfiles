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
opt.clipboard = opt.clipboard + 'unnamedplus'                        -- vim uses system clipboard to copy/paste
opt.title = true
opt.titlestring = '%m %F'
