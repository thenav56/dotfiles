return {
    {'junegunn/fzf'},
    {'junegunn/fzf.vim'},
    -- {'eugen0329/vim-esearch'},
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
    {'romainl/vim-qf'},
    {'sheerun/vim-polyglot'},
    {
        'norcalli/nvim-colorizer.lua',
        config = function()
            require'colorizer'.setup()
        end,
    },
    {
        -- help you read complex code by showing diff level of parentheses in diff color !!
        -- 'andymass/vim-matchup'
    },
    {
        -- spell check
        -- This handles snake_case and camelCase also
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
        "lukas-reineke/indent-blankline.nvim",
        config = function()
            require('plugin-configs/_indent-blankline')
        end,
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
        'nvim-treesitter/nvim-treesitter-context',
        config = function()
            require('plugin-configs/_nvim-treesitter-context')
        end,
    },
    {
        -- colorscheme
        'RRethy/nvim-base16',
        config = function()
            require('plugin-configs/_nvim-base16')
        end,
    },
    {
        'folke/zen-mode.nvim',
        config = function()
            require('plugin-configs/_zen-mode')
        end,
        dependencies = {
            'folke/twilight.nvim',
        }
    },
    -- {
    --     'kristijanhusak/vim-dadbod-ui',
    --     config = function()
    --         require('plugin-configs/_vim-dadbod-ui')
    --     end,
    --     dependencies = {
    --         { 'tpope/vim-dadbod', lazy = true },
    --         {
    --             'kristijanhusak/vim-dadbod-completion',
    --             ft = { 'sql', 'plsql' },
    --             lazy = true,
    --         },
    --     },
    -- },
    {
        -- misc
        'romainl/vim-qf'
    },
    {
        'folke/trouble.nvim',
        dependencies = { "nvim-tree/nvim-web-devicons", opt = true },
        config = function()
            require('plugin-configs/_trouble')
        end,
    }
}
