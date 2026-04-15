vim.schedule(function()
  vim.pack.add({
    "https://github.com/junegunn/fzf",
    "https://github.com/junegunn/fzf.vim",
  })
end)

vim.keymap.set('n', '<leader>bs', ':History<CR>', { silent = true })
vim.keymap.set('n', '<C-C>', ':Commands<CR>', { silent = true })
