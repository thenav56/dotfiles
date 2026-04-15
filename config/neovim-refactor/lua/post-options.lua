local vim = vim
local opt = vim.opt

-- FORMATTING
opt.backspace = 'indent,eol,start'
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.softtabstop = 4
opt.smartindent = true
opt.wrap = false
opt.title = true
opt.titlestring = '%m %F'

-- Autocommand for filetype-specific settings
local set_tab = function(ft, width)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = ft,
    callback = function()
      vim.opt_local.shiftwidth = width
      vim.opt_local.softtabstop = width
      vim.opt_local.tabstop = width
    end,
  })
end
set_tab({
  "javascript",
  "yaml",
  "json5",
  "json",
  "ts",
  "js",
  "lua",
}, 2)

local set_clipboard = function()
  local wezterm_executable = os.getenv("WEZTERM_EXECUTABLE")

  local local_tty = (
    os.getenv('SSH_TTY') == nil and (
      wezterm_executable == nil or not wezterm_executable:match("mux%-server$")
    )
  )

  if local_tty then
    opt.clipboard = opt.clipboard + 'unnamedplus'
  else
    vim.g.clipboard = 'osc52'
  end
end

set_clipboard()
