-- https://github.com/tinted-theming/base16-shell#neovim

local cmd = vim.cmd
local g = vim.g

local function read_file_first_line(file)
  if file == nil then
    return nil
  end

  local f = io.open(file, "r")
  if f == nil then
    return nil
  end

  local value = f:read()
  f:close()
  return value
end


local current_theme_name_from_env = os.getenv('BASE16_THEME')
local current_theme_from_file = read_file_first_line(os.getenv('BASE16_THEME_VIM_FILE'))
local current_theme_name = current_theme_from_file or current_theme_name_from_env

if current_theme_name and g.colors_name ~= 'base16-'..current_theme_name then
  cmd('colorscheme base16-'..current_theme_name)
end
