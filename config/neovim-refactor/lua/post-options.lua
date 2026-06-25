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

local function set_clipboard()
  local use_osc52 =
    os.getenv("HERDR_ENV")
    or os.getenv("SSH_TTY")
    or (
      os.getenv("WEZTERM_EXECUTABLE")
      and os.getenv("WEZTERM_EXECUTABLE"):match("mux%-server$")
    )

  if use_osc52 then
    vim.g.clipboard = "osc52"
  else
    vim.opt.clipboard:append("unnamedplus")
  end
end

set_clipboard()
