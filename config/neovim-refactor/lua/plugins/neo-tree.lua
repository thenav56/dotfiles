vim.pack.add({
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/MunifTanjim/nui.nvim",
  "https://github.com/nvim-tree/nvim-web-devicons",
  {
    src = 'https://github.com/nvim-neo-tree/neo-tree.nvim',
    version = vim.version.range('3')
  },
})

local bit = require("bit")

local function toggle_executable(state)
  local node = state.tree:get_node()
  local path = node.path

  local stat = vim.loop.fs_stat(path)
  if not stat then return end

  local is_executable = bit.band(stat.mode, 0x49) ~= 0

  if is_executable then
    vim.fn.system({ "chmod", "-x", path })
    print("Removed executable bit: " .. path)
  else
    vim.fn.system({ "chmod", "+x", path })
    print("Made executable: " .. path)
  end

  require("neo-tree.sources.manager").refresh(state.name)
end

-- NOTE: <tab> == ctrl-i (opposite to ctrl+o), so using <leader-tab> instead
-- https://github.com/neovim/neovim/issues/5916
vim.keymap.set("", "<leader><tab>", ":Neotree toggle<CR>", { silent = true, remap = false })

require("neo-tree").setup({
  window = {
    position = "left",
  },
  filesystem = {
    filtered_items = {
      visible = true, -- when true, they will just be displayed differently than normal items
    },
    follow_current_file = {
      enabled = true,
      leave_dirs_open = true,
    },
    window = {
      mappings = {
        ["/"] = "",
        -- Additional
        ["//"] = "fuzzy_finder",
        ["X"] = toggle_executable,
      }
    },
  },
})
