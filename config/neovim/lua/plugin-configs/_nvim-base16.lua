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


local current_theme_name = read_file_first_line(os.getenv('VIM_ACTIVE_THEME_FILE'))

-- Try with env again
if (current_theme_name == nil or current_theme_name == '') then
    current_theme_name = 'base16-' .. os.getenv('BASE16_THEME')
end

if current_theme_name and g.colors_name ~= current_theme_name then
  cmd('colorscheme '..current_theme_name)
end
