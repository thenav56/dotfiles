lua << EOF
    local nvim_lsp = require('lspconfig')
    local util = require('lspconfig/util')

    local path = util.path

    local function get_python_path(workspace)
      -- Use activated virtualenv.
      if vim.env.VIRTUAL_ENV then
        return path.join(vim.env.VIRTUAL_ENV, 'bin', 'python')
      end

      --[[
      -- Find and use virtualenv in workspace directory.
      for _, pattern in ipairs({'*', '.*'}) do
        local match = vim.fn.glob(path.join(workspace, pattern, 'pyvenv.cfg'))
        if match ~= '' then
          return path.join(path.dirname(match), 'bin', 'python')
        end
      end
      --]]

      -- Find and use virtualenv via poetry in workspace directory.
      local match = vim.fn.glob(path.join(workspace, 'poetry.lock'))
      if match ~= '' then
        local venv = vim.fn.trim(vim.fn.system('poetry env info -p'))
        return path.join(venv, 'bin', 'python')
      end

      -- Fallback to system Python.
      return exepath('python3') or exepath('python') or 'python'
    end

    local before_init = function(_, config)
        config.settings.python.pythonPath = get_python_path(config.root_dir)
    end

    -- Use an on_attach function to only map the following keys
    -- after the language server attaches to the current buffer
    local on_attach = function(client, bufnr)
        local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
        local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

        --Enable completion triggered by <c-x><c-o>
        buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

        -- Mappings.
        local opts = { noremap=true, silent=true }

        -- See `:help vim.lsp.*` for documentation on any of the below functions
        buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
        buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
        buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
        buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
        buf_set_keymap('n', 'gt', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)

        buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
        buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)

        buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
        buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)

        -- buf_set_keymap('n', '<leader>lr', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
        buf_set_keymap('n', '<leader>lc', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
        buf_set_keymap('n', '<leader>ld', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
        buf_set_keymap('n', '<leader>ll', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
        buf_set_keymap('n', '<leader>lf', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
    end

    -- Use a loop to conveniently call 'setup' on multiple servers and
    -- map buffer local keybindings when the language server attaches
    local servers = { 'pyright', 'tsserver' }
    for _, lsp in ipairs(servers) do
        nvim_lsp[lsp].setup {
            on_attach = on_attach,
            before_init = before_init,
            flags = {
                debounce_text_changes = 200,
            }
        }
    end
EOF

" -- Navin
" lua << EOF
"     -- Find and use virtualenv via poetry in workspace directory.
"     local path = require('lspconfig/util').path
"     local function get_python_path(workspace)
"         local match = vim.fn.glob(path.join(workspace, 'poetry.lock'))
"         if match ~= '' then
"           local venv = vim.fn.trim(vim.fn.system('poetry env info -p'))
"           return path.join(venv, 'bin', 'python')
"         end
"     end
" 
" 
"     local nvim_lsp = require('lspconfig')
"     -- Use an on_attach function to only map the following keys
"     -- after the language server attaches to the current buffer
"     local on_attach = function(client, bufnr)
"       local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
"       local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end
" 
"       --Enable completion triggered by <c-x><c-o>
"       buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')
" 
"       -- Mappings.
"       local opts = { noremap=true, silent=true }
" 
"       -- See `:help vim.lsp.*` for documentation on any of the below functions
"       buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
"       buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
"       buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
"       buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
"       buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
"       buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
"       buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
"       buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
"       buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
"       buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
"       buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
"       buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
"       buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
"       buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
"       buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
"       buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
"       buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
" 
"     end
" 
"     -- Use a loop to conveniently call 'setup' on multiple servers and
"     -- map buffer local keybindings when the language server attaches
"     local servers = { "rust_analyzer", "tsserver", "dockerls" }
"     for _, lsp in ipairs(servers) do
"       nvim_lsp[lsp].setup {
"         on_attach = on_attach,
"         flags = {
"           debounce_text_changes = 150,
"         }
"       }
"     end
"     nvim_lsp["pyright"].setup {
"         on_attach = on_attach,
"         flags = {
"           debounce_text_changes = 150,
"         },
"         before_init = function(_, config)
"           config.settings.python.pythonPath = get_python_path(config.root_dir)
"         end
"     }
" EOF
" 
lua << EOF
    -- Compe setup
    require'compe'.setup {
      enabled = true;
      autocomplete = true;
      debug = false;
      min_length = 1;
      preselect = 'enable';
      throttle_time = 80;
      source_timeout = 200;
      incomplete_delay = 400;
      max_abbr_width = 100;
      max_kind_width = 100;
      max_menu_width = 100;
      documentation = true;

      source = {
        path = true;
        nvim_lsp = true;
      };
    }

    local t = function(str)
      return vim.api.nvim_replace_termcodes(str, true, true, true)
    end

    local check_back_space = function()
        local col = vim.fn.col('.') - 1
        if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
            return true
        else
            return false
        end
    end

    -- Use (s-)tab to:
    --- move to prev/next item in completion menuone
    --- jump to prev/next snippet's placeholder
    _G.tab_complete = function()
      if vim.fn.pumvisible() == 1 then
        return t "<C-n>"
      elseif check_back_space() then
        return t "<Tab>"
      else
        return vim.fn['compe#complete']()
      end
    end
    _G.s_tab_complete = function()
      if vim.fn.pumvisible() == 1 then
        return t "<C-p>"
      else
        return t "<S-Tab>"
      end
    end

    vim.api.nvim_set_keymap("i", "<Tab>", "v:lua.tab_complete()", {expr = true})
    vim.api.nvim_set_keymap("s", "<Tab>", "v:lua.tab_complete()", {expr = true})
    vim.api.nvim_set_keymap("i", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})
    vim.api.nvim_set_keymap("s", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})
EOF
