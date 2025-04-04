local telescope = require('telescope')
local actions = require('telescope.actions')
local builtin = require('telescope.builtin')
local telescope_trouble = require("trouble.sources.telescope")

local select_one_or_multi = function(prompt_bufnr)
  local picker = require('telescope.actions.state').get_current_picker(prompt_bufnr)
  local multi = picker:get_multi_selection()
  if not vim.tbl_isempty(multi) then
    require('telescope.actions').close(prompt_bufnr)
    for _, j in pairs(multi) do
      if j.path ~= nil then
        vim.cmd(string.format('%s %s', 'edit', j.path))
      end
    end
  else
    require('telescope.actions').select_default(prompt_bufnr)
  end
end


telescope.setup {
  defaults = {
    mappings = {
        i = {
            ["<esc>"] = actions.close,
            ['<CR>'] = select_one_or_multi,
            ["<C-j>"] = {
                actions.move_selection_next, type = "action",
                opts = { nowait = true, silent = true }
            },
            ["<C-k>"] = {
                actions.move_selection_previous, type = "action",
                opts = { nowait = true, silent = true }
            },
            ["<c-f>"] = telescope_trouble.open
        },
    }
  },
}

telescope.load_extension('live_grep_args')

-- Copied from https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/util/init.lua#L20C10-L20C65
if require("lazy.core.config").spec.plugins['noice.nvim'] ~= nil then
    telescope.load_extension('noice')
end

vim.keymap.set('n', '<leader>ff', function() builtin.find_files({
    hidden = true,
}) end, { silent = true })

vim.keymap.set('n', '<leader>fa', function() builtin.live_grep() end, { silent = true })
vim.keymap.set('n', '<leader>fs', builtin.grep_string, { silent = true })
vim.keymap.set('n', '<leader>fb', builtin.oldfiles, { silent = true })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { silent = true })
vim.keymap.set('n', ';', function() builtin.buffers({
    sort_lastused = true,
    -- ignore_current_buffer = true,
    sort_mru = true,
}) end, { silent = true })
