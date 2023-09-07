return {
    {'junegunn/fzf'},
    {'junegunn/fzf.vim'},
    {
        -- fuzzy search
        'nvim-telescope/telescope.nvim',
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-telescope/telescope-live-grep-raw.nvim',
        },
        config = function()
            require('plugin-configs/_telescope')
        end,
    },
    {'lambdalisue/suda.vim'},
    {'sheerun/vim-polyglot'},
    {'lukas-reineke/indent-blankline.nvim'},
    {
        -- help you read complex code by showing diff level of parentheses in diff color !!
        -- 'andymass/vim-matchup'
    },
    {
        -- spell check
        'kamykn/spelunker.vim',
        config = function()
            require('plugin-configs/_spelunker')
        end,
    },
    {
        -- GnuPG decrypt/encrypt gpg files
        'jamessan/vim-gnupg',
        config = function()
            require('plugin-configs/_vim-gnupg')
        end,
    },
    {
        'goolord/alpha-nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        config = function ()
            require('plugin-configs/_alpha-nvim')
        end
    },
    {
        'numToStr/Comment.nvim',
        config = function()
            require('plugin-configs/_Comment')
        end,
        lazy = false,
    },
    -- git
    {'tpope/vim-fugitive'},
    {
        'lewis6991/gitsigns.nvim',
        config = function()
            require('plugin-configs/_gitsigns')
        end,
    },
    {
        'nvim-lualine/lualine.nvim',
        config = function()
            require('plugin-configs/_lualine')
        end,
        dependencies = { 'nvim-tree/nvim-web-devicons', opt = true },
    },
    {
        -- File nagivator
        "ms-jpq/chadtree",
        branch = "chad",
        build = "python3 -m chadtree deps",
        config = function()
            require('plugin-configs/_chadtree')
        end,
        dependencies = {
            {
                {'ryanoasis/vim-devicons', opt = true},
                {'adelarsq/vim-emoji-icon-theme', opt = true},
            }
        },
    },
    {
        -- Manage external dependencies
        'williamboman/mason.nvim',
        build = ':MasonUpdate', -- :MasonUpdate updates registry contents
        config = function()
            require('plugin-configs/_mason')
        end,
    },
    {
        -- Manage external dependencies for lsp
        'williamboman/mason-lspconfig.nvim',
        config = function()
            require('plugin-configs/_mason-lspconfig')
        end,
        dependencies = {
            'williamboman/mason.nvim',
        }
    },
    {
        -- lsp support
        'neovim/nvim-lspconfig',
        config = function()
            require('plugin-configs/_lspconfig')
        end,
        dependencies = {
            'williamboman/mason-lspconfig.nvim',
            'hrsh7th/nvim-cmp',
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'hrsh7th/cmp-cmdline',
            'hrsh7th/nvim-cmp',
        },
    },
    {
        -- treesitter support
        'nvim-treesitter/nvim-treesitter',
        config = function()
            require('plugin-configs/_nvim-treesitter')
        end,
    },
    {
        -- colorscheme
        'RRethy/nvim-base16',
        config = function()
            require('plugin-configs/_nvim-base16')
        end,
    },
}
