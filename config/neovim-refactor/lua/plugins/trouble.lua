vim.pack.add({ "https://github.com/folke/trouble.nvim" })

require("trouble").setup({})

-- Trouble
vim.keymap.set("n", "<leader>xx", ":Trouble diagnostics toggle<CR>")  -- Diagnostics (Trouble)
vim.keymap.set("n", "<leader>xd", ":Trouble diagnostics toggle filter.buf=0<CR>")  -- Buffer Diagnostics (Trouble)
vim.keymap.set("n", "<leader>xq", ":Trouble qflist toggle<CR>")  -- Quickfix List (Trouble)
vim.keymap.set("n", "<leader>xl", ":Trouble loclist toggle<CR>")  -- Location List (Trouble)
vim.keymap.set("n", "<leader>xs", ":Trouble symbols toggle focus=false<CR>")  -- Symbols (Trouble)
vim.keymap.set("n", "gR", ":Trouble lsp toggle focus=false win.position=right<CR>")  -- LSP Definitions / references / ... (Trouble)
-- Move to next/previous troubles
vim.keymap.set("n", "[t", function() require("trouble").next({skip_groups = true, jump = true}) end)
vim.keymap.set("n", "]t", function() require("trouble").previous({skip_groups = true, jump = true}) end)
