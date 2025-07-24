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

-- Autocommand for filetype-specific settings
local set_tab = function(ft, opts)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = ft,
    callback = function()
      for key, value in pairs(opts) do
        vim.opt_local[key] = value
      end
    end,
  })
end

-- Customize per filetype
set_tab("python", { expandtab = true, shiftwidth = 4, softtabstop = 4, tabstop = 4 })
set_tab("javascript", { expandtab = true, shiftwidth = 2, softtabstop = 2, tabstop = 2 })
set_tab("yaml", { expandtab = true, shiftwidth = 2, softtabstop = 2, tabstop = 2 })
set_tab("json5", { expandtab = true, shiftwidth = 2, softtabstop = 2, tabstop = 2 })

local set_clipboard = function()
    -- When using wezterm as tmux
    local wezterm_executable = os.getenv("WEZTERM_EXECUTABLE")

    local local_tty = (
        os.getenv('SSH_TTY') == nil and (
            wezterm_executable == nil or not wezterm_executable:match("mux%-server$")
        )
    )

    if local_tty then
        opt.clipboard = opt.clipboard + 'unnamedplus'                        -- vim uses system clipboard to copy/paste
    else
        -- This is used to forward clipboard to ssh client host
        -- https://sw.kovidgoyal.net/kitty/clipboard/
        -- NOTE: Use "+y to copy from ssh connection neovim
        vim.g.clipboard = 'osc52'
    end
end

set_clipboard()
