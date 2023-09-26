local telescope = require('telescope')
local actions = require('telescope.actions')
local builtin = require('telescope.builtin')

local common_mappings = {
  i = {
    ["<esc>"] = actions.close,
    ["<C-j>"] = {
      actions.move_selection_next, type = "action",
      opts = { nowait = true, silent = true }
    },
    ["<C-k>"] = {
      actions.move_selection_previous, type = "action",
      opts = { nowait = true, silent = true }
    },
  },
}

require("telescope").setup {
  pickers = {
    find_files = {
      mappings = common_mappings,
    },
    live_grep = {
      mappings = common_mappings,
    },
    grep_string = {
      mappings = common_mappings,
    },
    buffers = {
      mappings = common_mappings,
    },
    oldfiles = {
      mappings = common_mappings,
    },
    help_tags = {
      mappings = common_mappings,
    },
  },
}

telescope.load_extension('live_grep_args')

-- Copied from https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/util/init.lua#L20C10-L20C65
if require("lazy.core.config").spec.plugins['noice.nvim'] ~= nil then
    telescope.load_extension('noice')
end

vim.keymap.set('n', '<leader>ff', function() builtin.find_files({ hidden = true }) end, { silent = true })
vim.keymap.set('n', '<leader>fa', builtin.live_grep, { silent = true })
vim.keymap.set('n', '<leader>fs', builtin.grep_string, { silent = true })
vim.keymap.set('n', '<leader>fb', builtin.oldfiles, { silent = true })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { silent = true })
vim.keymap.set('n', ';', function() builtin.buffers({ sort_lastused = true }) end, { silent = true })
