-- REPLACE: Please replace this with your own gpg receipient emails
-- vim.g.GPGDefaultRecipients = {'example@example.com'}

vim.api.nvim_create_autocmd({'BufRead', 'BufNewFile'}, {
    pattern = {"*.gpg"},
    command = "User GnuPG setl textwidth=72",
})
