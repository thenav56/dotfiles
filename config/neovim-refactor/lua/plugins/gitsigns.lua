vim.pack.add({ 'https://github.com/lewis6991/gitsigns.nvim' })

require('gitsigns').setup({
    signcolumn = true,
    numhl = true,
    current_line_blame = true,
})
