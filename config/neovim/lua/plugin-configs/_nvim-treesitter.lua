local vim = vim
local opt = vim.opt

--
-- # treesitter-context configs
-- https://github.com/nvim-treesitter/nvim-treesitter-context?tab=readme-ov-file#configuration
require'treesitter-context'.setup{
  enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
  max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
  min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
  line_numbers = true,
  multiline_threshold = 20, -- Maximum number of lines to show for a single context
  trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
  mode = 'cursor',  -- Line used to calculate context. Choices: 'cursor', 'topline'
  -- Separator between context and content. Should be a single character string, like '-'.
  -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
  separator = nil,
  zindex = 20, -- The Z-index of the context window
  on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
}

-- # vim-match
vim.o.matchpairs = '(:),{:},[:]'
vim.g.matchup_matchparen_offscreen = { method = 'popup' }

-- # Folding - https://github.com/nvim-treesitter/nvim-treesitter?tab=readme-ov-file#folding
opt.foldmethod = 'expr'
opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
opt.foldlevelstart = 0
opt.foldnestmax = 4


-- # Basic treesitter configs
require('nvim-treesitter.configs').setup {
    ensure_installed = {
        'bash',
        'css',
        'dockerfile',
        'gitattributes',
        'gitcommit',
        'git_config',
        'gitignore',
        'git_rebase',
        'graphql',
        'html',
        'javascript',
        'json',
        -- 'lua',
        'markdown',
        'python',
        'regex',
        'sql',
        'tsx',
        'typescript',
        'yaml',
    },
    highlight = {
        enable = false,
    },
    indent = {
        enable = false
    },
    -- # vim-match
    matchup = {
        enable = true,
    }
}
