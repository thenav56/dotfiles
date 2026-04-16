vim.pack.add({
  "https://github.com/williamboman/mason-lspconfig.nvim",
  "https://github.com/hrsh7th/nvim-cmp",
  "https://github.com/hrsh7th/cmp-nvim-lsp",
  "https://github.com/hrsh7th/cmp-buffer",
  "https://github.com/hrsh7th/cmp-path",
  "https://github.com/hrsh7th/cmp-cmdline",
  { src = "https://github.com/neovim/nvim-lspconfig", version = "main"},
})

local cmp = require('cmp')
local lspconfig_util = require('lspconfig/util')

-- Completion
vim.opt.completeopt = {
  "menu",
  "menuone",
  "fuzzy",
  "noinsert",
  "noselect",
  "popup",
}


-- Completion setup
cmp.setup({
  completion = {
      autocomplete = false,
  },
  performance = {
      max_view_entries = 5,
      fetching_timeout = 1,
      debounce = 0,
      throttle = 0,
      confirm_resolve_timeout = 80,
      async_budget = 1,
  },
  window = {
    documentation = cmp.config.window.bordered(),
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<TAB>'] = cmp.mapping.select_next_item(),
    ['<S-TAB>'] = cmp.mapping.select_prev_item(),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
  }),
  sources = cmp.config.sources({
    {
        name = 'nvim_lsp',
        entry_filter = function (entry, ctx)
            return require('cmp.types').lsp.CompletionItemKind[entry:get_kind()] ~= 'Text'
        end
    }
  }, {
    {
        name = 'buffer',
        entry_filter = function(entry, ctx)
            -- Filter out super long texts
            return string.len(entry:get_word()) < 40
        end
    }
  }, {
    { name = 'path' }
  })
})

-- Set configuration for specific filetype.
cmp.setup.filetype('gitcommit', {
  sources = cmp.config.sources({
    { name = 'git' }, -- You can specify the `git` source if [you were installed it](https://github.com/petertriho/cmp-git).
  }, {
    { name = 'buffer' },
  })
})

-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline({ '/', '?' }, {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = 'buffer' }
  },
  performance = {
      max_view_entries = 5,
  },
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = 'path' }
  }, {
    { name = 'cmdline' }
  })
})

-- The nvim-cmp almost supports LSP's capabilities so You should advertise it to LSP servers..
local capabilities = require('cmp_nvim_lsp').default_capabilities()
-- TODO: local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.offsetEncoding = { 'utf-16' }
capabilities.general = {
    positionEncodings = { 'utf-16' },
}

-- Diagnostic signs
vim.diagnostic.config({
    virtual_text = true,
    -- virtual_lines = true,
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = '⛔',
            [vim.diagnostic.severity.WARN] = '⚠️',
            [vim.diagnostic.severity.HINT] = '💡',
            [vim.diagnostic.severity.INFO] = 'i',
        }
    }
})

vim.lsp.document_color.enable(true, nil, { style = "virtual" })

vim.lsp.config('*', {
  capabilities = capabilities,
})
-- TODO: Remove this if config('*') works?
-- vim.lsp.config('tflint', {capabilities = capabilities})
-- vim.lsp.config('terraformls', {capabilities = capabilities})
-- vim.lsp.config('ts_ls', {capabilities = capabilities})
-- vim.lsp.config('graphql', {capabilities = capabilities})
-- vim.lsp.config('bashls', {capabilities = capabilities})
-- vim.lsp.config('docker_compose_language_service', {capabilities = capabilities})
-- vim.lsp.config('html', {capabilities = capabilities})
-- vim.lsp.config('jsonls', {capabilities = capabilities})
-- vim.lsp.config('sqlls', {capabilities = capabilities})
-- vim.lsp.config('yamlls', {capabilities = capabilities})
-- vim.lsp.config('nginx_language_server', { capabilities = capabilities })
-- vim.lsp.config('gh_actions_ls', {  capabilities = capabilities })
-- vim.lsp.config('postgres_lsp', {  capabilities = capabilities })

local function get_python_path(workspace)
  -- Use activated virtualenv.
  if vim.env.VIRTUAL_ENV then
    return lspconfig_util.path.join(vim.env.VIRTUAL_ENV, 'bin', 'python')
  end

  -- Find and use virtualenv via poetry in workspace directory.
  local match = vim.fn.glob(lspconfig_util.path.join(workspace, 'poetry.lock'))
  if match ~= '' then
    local venv = vim.fn.trim(vim.fn.system('poetry env info -p'))
    return lspconfig_util.path.join(venv, 'bin', 'python')
  end

  -- Look for command virtual env paths as well
  local venv_paths = {".venv", "venv"}
  for index = 1, #venv_paths, 1 do
      local venv_path = venv_paths[index]
      match = vim.fn.glob(lspconfig_util.path.join(workspace, venv_path))
      local python_path = lspconfig_util.path.join(venv_path, 'bin', 'python')
      if match ~= '' and vim.fn.exepath(python_path) then
        return python_path
      end
  end

  -- Fallback to system Python.
  return vim.fn.exepath('python3') or vim.fn.exepath('python') or 'python'
end

vim.lsp.config('ruff', {
  capabilities = capabilities,
  init_options = {
    settings = {
      lint = {
        preview = true
      },
    }
  }
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup('lsp_attach_disable_ruff_hover', { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client == nil then
      return
    end
    if client.name == 'ruff' then
      -- Disable hover in favor of Pyright
      client.server_capabilities.hoverProvider = false
    end
  end,
  desc = 'LSP: Disable hover capability from Ruff',
})

vim.api.nvim_create_user_command(
    'Ruff',
    function()
        vim.lsp.buf.code_action {
            context = {
                only = { 'source.fixAll.ruff' }
            },
            apply = true,
        }
        vim.lsp.buf.format { async = true }
    end,
    { desc = "Reformat python with ruff" }
)

vim.lsp.config('pyright', {
  capabilities = capabilities,
  before_init = function(_, config)
      config.settings.python.pythonPath = get_python_path(config.root_dir or "")
  end,
  settings = {
    pyright = {
      -- Using Ruff's import organizer
      disableOrganizeImports = true,
    },
    python = {
      analysis = {
        -- Ignore all files for analysis to exclusively use Ruff for linting
        -- ignore = { '*' },
      },
    },
  },
})

vim.lsp.config('dockerls', {
    capabilities = capabilities,
    on_init = function(client, initialization_result)
        if client.server_capabilities then
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.semanticTokensProvider = false
        end
    end,
})

vim.lsp.config('eslint', {
    capabilities = capabilities,
    settings = {
        eslint = {
            -- https://github.com/LazyVim/LazyVim/issues/3383
            useFlatConfig = false,
        }
    }
})

vim.lsp.config('lua_ls', {
  capabilities = capabilities,
  settings = {
    Lua = {
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        globals = {'vim', 'exepath'},
      },
    },
  },
})

vim.lsp.config('stylelint_lsp', {
  capabilities = capabilities,
    filetypes = {
        'css', 'less', 'scss', 'sugarss', 'wxss',
    },
})

vim.lsp.config('harper_ls', {
    -- https://writewithharper.com/docs/integrations/neovim#Optional-Configuration
    filetypes = { "markdown" },
})

-- Global mappings.
-- For default mapping, checkout `:help diagnostic-defaults`
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
vim.keymap.set('n', '<leader>ll', vim.diagnostic.setloclist)

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('UserLspConfig', {}),
    callback = function(ev)
        -- Enable completion triggered by <c-x><c-o>
        vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

        -- Buffer local mappings.
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        local opts = {
          buffer = ev.buf,
        }

        -- Default mapping `help lsp-defaults`
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
        vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, opts)
        vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)

        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)

        vim.keymap.set('n', '<leader>lr', vim.lsp.buf.rename, opts)
        vim.keymap.set({ 'n', 'v' }, '<leader>lc', vim.lsp.buf.code_action, opts)
        vim.keymap.set('n', '<leader>lf', function()
            vim.lsp.buf.format { async = true }
        end, opts)
    end,
})
