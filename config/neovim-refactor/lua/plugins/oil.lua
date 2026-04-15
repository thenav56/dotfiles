vim.pack.add({
  "https://github.com/nvim-tree/nvim-web-devicons",
  "https://github.com/stevearc/oil.nvim",
})

require("oil").setup{
  view_options = {
      show_hidden = true,
  }
}

vim.keymap.set('n', '-', '<CMD>Oil<CR>', { noremap = true, silent = true, desc = 'Open parent directory' })
