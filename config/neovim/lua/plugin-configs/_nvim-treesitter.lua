local vim = vim

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

require('nvim-treesitter').setup {
  install_dir = vim.fn.stdpath('data') .. '/nvim-treesitter'
}

local languages = {
    -- https://github.com/tree-sitter/tree-sitter/wiki/List-of-parsers
    'bash',
    'nginx',
    'graphql',
    'comment',
    'css',
    'dockerfile',
    'gitattributes',
    'gitcommit',
    'git_config',
    'gitignore',
    'git_rebase',
    'html',
    'javascript',
    'json',
    'caddy',
    -- 'lua',
    'markdown',
    'diff',
    'python',
    'regex',
    'sql',
    'tsx',
    'typescript',
    'yaml',
    -- Helm
    'gotmpl',
    'helm',
    'terraform',
    'hcl',
}
require('nvim-treesitter').install { languages }

-- # Basic treesitter configs

vim.api.nvim_create_autocmd('FileType', {
  pattern = languages,
  callback = function()
    -- syntax highlighting, provided by Neovim
    vim.treesitter.start()
    -- folds, provided by Neovim
    vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    vim.wo.foldmethod = 'expr'
    -- indentation, provided by nvim-treesitter
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

-- Filetype detection for Helm and other custom types
-- For Helm support, see: https://github.com/ngalaiko/tree-sitter-go-template#neovim-integration-using-nvim-treesitter

vim.filetype.add({
  extension = {
    gotmpl = "gotmpl",
    caddy = "caddy",
  },
  pattern = {
    [".*/templates/.*%.tpl"] = "gotmpl",
    [".*/templates/.*%.ya?ml"] = "helm",
    ["helmfile.*%.ya?ml"] = "helm",
    ["Caddyfile"] = "caddy",
  },
})
