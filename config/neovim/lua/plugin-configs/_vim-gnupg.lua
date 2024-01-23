-- Define VimGPGDefaultRecipients in your zshrc

-- Example: example@gmail.com
local default_recipients_raw = os.getenv('VimGPGDefaultRecipients') or ''

local default_recipients = {}
for str in string.gmatch(default_recipients_raw, '([^'..','..']+)') do
    table.insert(default_recipients, str)
end

vim.g.GPGDefaultRecipients = default_recipients

vim.api.nvim_create_autocmd({'BufRead', 'BufNewFile'}, {
    pattern = {'*.gpg'},
    command = 'User GnuPG setl textwidth=72',
})
