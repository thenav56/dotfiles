-- https://github.com/tinted-theming/base16-shell#neovim

local cmd = vim.cmd
local g = vim.g

local current_theme_name = os.getenv('BASE16_THEME')
if current_theme_name and g.colors_name ~= 'base16-'..current_theme_name then
  cmd('colorscheme base16-'..current_theme_name)
end
