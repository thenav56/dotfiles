-- https://echasnovski.com/blog/2026-03-13-a-guide-to-vim-pack

vim.pack.add({
  "https://github.com/lambdalisue/suda.vim",
})

require("plugins/trouble")
require("plugins/telescope")
require("plugins/fzf")

require("plugins/spelunker")  -- Spell
require("plugins/vim-gnupg")
require("plugins/indent-blankline")
require("plugins/comment")

-- Git
require("plugins/gitsigns")
require("plugins/git-conflict")

require("plugins/lualine")

require("plugins/chadtree")
require("plugins/oil")

require("plugins/ufo")  -- Folding

require("plugins/none_ls")

require("plugins/base16")  -- Theme

require("plugins/nvim-treesitter") -- Treesitter

-- LSP
require("plugins/lsp/mason")
require("plugins/lsp/nvim-lspconfig")
