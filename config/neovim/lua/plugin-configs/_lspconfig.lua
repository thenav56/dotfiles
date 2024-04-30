local lspconfig = require('lspconfig')
local cmp = require('cmp')
local util = require('lspconfig/util')
local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup
local map = vim.keymap.set
local lsp = vim.lsp
local fn = vim.fn
local inspect = vim.inspect
local bo = vim.bo
local diagnostic = vim.diagnostic
local env = vim.env


-- Completion setup
cmp.setup({
  performance = {
      max_view_entries = 10,
      fetching_timeout = 1,
  },
  window = {
    -- completion = cmp.config.window.bordered(),
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
    { name = 'nvim_lsp' }
  }, {
    { name = 'buffer' }
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

-- Diagnostic signs
local signs = { Error = "⛔", Warn = "⚠️", Hint = "💡", Info = "ℹ️ " }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

local function get_python_path(workspace)
  -- Use activated virtualenv.
  if env.VIRTUAL_ENV then
    return util.path.join(env.VIRTUAL_ENV, 'bin', 'python')
  end

  -- Find and use virtualenv via poetry in workspace directory.
  local match = fn.glob(util.path.join(workspace, 'poetry.lock'))
  if match ~= '' then
    local venv = fn.trim(fn.system('poetry env info -p'))
    return util.path.join(venv, 'bin', 'python')
  end

  -- Fallback to system Python.
  return exepath('python3') or exepath('python') or 'python'
end


lspconfig.pyright.setup {
    capabilities = capabilities,
    before_init = function(_, config)
        config.settings.python.pythonPath = get_python_path(config.root_dir)
    end
}

-- https://github.com/williamboman/mason-lspconfig.nvim/blob/main/lua/mason-lspconfig/server_configurations/pylsp/README.md
lspconfig.pylsp.setup {
  capabilities = capabilities,
  -- https://github.com/python-lsp/python-lsp-server/blob/develop/CONFIGURATION.md
  settings = {
    pylsp = {
      configurationSources = {"flake8"},
      plugins = {
        flake8 = {
          enabled = true,
        },
        autoimport = {
          enabled = false,
        },
        -- ruff = {
        --     enabled = true,
        -- }
      }
    }
  }
}

lspconfig.tsserver.setup {capabilities = capabilities}
lspconfig.graphql.setup {capabilities = capabilities}
lspconfig.bashls.setup {capabilities = capabilities}
-- lspconfig.cssmodules_ls.setup {}
lspconfig.docker_compose_language_service.setup {capabilities = capabilities}
lspconfig.dockerls.setup {capabilities = capabilities}
lspconfig.eslint.setup {capabilities = capabilities}
lspconfig.html.setup {capabilities = capabilities}
lspconfig.jsonls.setup {capabilities = capabilities}
lspconfig.lua_ls.setup {
  capabilities = capabilities,
  settings = {
    Lua = {
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        globals = {'vim', 'exepath'},
      },
    },
  },
}
lspconfig.sqlls.setup {capabilities = capabilities}
lspconfig.stylelint_lsp.setup {
  capabilities = capabilities,
    filetypes = {
        'css', 'less', 'scss', 'sugarss', 'wxss',
    },
}
lspconfig.yamlls.setup {capabilities = capabilities}
lspconfig.nginx_language_server.setup { capabilities = capabilities }

-- Global mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
map('n', '[d', diagnostic.goto_prev)
map('n', ']d', diagnostic.goto_next)
map('n', '<leader>ld', diagnostic.open_float)
map('n', '<leader>ll', diagnostic.setloclist)

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
autocmd('LspAttach', {
    group = augroup('UserLspConfig', {}),
    callback = function(ev)
        -- Enable completion triggered by <c-x><c-o>
        bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

        -- Buffer local mappings.
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        local opts = {
          buffer = ev.buf,
        }

        map('n', 'gD', lsp.buf.declaration, opts)
        map('n', 'gd', lsp.buf.definition, opts)
        map('n', 'gt', lsp.buf.type_definition, opts)
        map('n', 'gi', lsp.buf.implementation, opts)
        map('n', 'gr', lsp.buf.references, opts)

        map('n', 'K', lsp.buf.hover, opts)
        map('n', '<C-k>', lsp.buf.signature_help, opts)

        map('n', '<space>wa', lsp.buf.add_workspace_folder, opts)
        map('n', '<space>wr', lsp.buf.remove_workspace_folder, opts)
        map('n', '<space>wl', function()
            print(inspect(lsp.buf.list_workspace_folders()))
        end, opts)

        map('n', '<leader>lr', lsp.buf.rename, opts)
        map({ 'n', 'v' }, '<leader>lc', lsp.buf.code_action, opts)
        map('n', '<leader>lf', function()
            lsp.buf.format { async = true }
        end, opts)
    end,
})
