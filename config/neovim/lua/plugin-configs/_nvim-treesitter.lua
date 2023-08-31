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
    }
}
