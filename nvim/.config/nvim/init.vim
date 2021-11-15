set nocompatible
filetype off
call plug#begin('~/.config/nvim/plugged')

" Visual
Plug 'itchyny/lightline.vim'                " Status line
Plug 'Yggdroot/indentLine'                  " Indent lines
Plug 'mhinz/vim-startify'                   " Startup page
Plug 'chriskempson/base16-vim'              " Themes
Plug 'ryanoasis/vim-devicons'               " Icons
Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/nvim-compe'
Plug 'nvim-lua/completion-nvim'
Plug 'glacambre/firenvim', { 'do': { _ -> firenvim#install(0) } }

" Git
Plug 'tpope/vim-fugitive'                   " git wrapper for git e.g Gdiff :P
Plug 'airblade/vim-gitgutter'               " shows git diff

" Navigation / Search
" Plug 'scrooloose/nerdtree'                  " file explorer
Plug 'ms-jpq/chadtree', {'branch': 'chad', 'do': 'python3 -m chadtree deps'}
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'                     " FZF bro!

" Language support
Plug 'w0rp/ale'                             " Awesome aync linter manager
Plug 'sheerun/vim-polyglot'                 " A solid language packs for vim
Plug 'kamykn/spelunker.vim'                 " Improved vim spelling plugin
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() } }  " Markdown

" Misc
Plug 'lambdalisue/suda.vim'                 " Ask pass when needed
Plug 'qpkorr/vim-bufkill'                   " Remove files from buffer
Plug 'eugen0329/vim-esearch'                " Search
Plug 'tpope/vim-commentary'                 " comment stuffs in/out
" Plug 'wakatime/vim-wakatime'                " tracks hours to wakatime site
" Plug 'git-time-metric/gtm-vim-plugin'       " tracks hours for gtm

call plug#end()

" Now we can turn our filetype functionality back on
filetype plugin on
syntax on

" GENERAL
set synmaxcol=250                                   " syntax highlighting line size limit
set nocompatible                                    " Don't behave very Vi compatible
set encoding=utf-8                                  " Set character encoding
set lazyredraw                                      " Don't draw while executing macros
set hidden                                          " Don't unload a buffer when no longer show in window
set nofoldenable                                    " Set to display all folds open
set remap                                           " Recognize mappings in mapped keys
set nospell                                         " Disable spell correction
set scroll=9                                        " Number of lines to scroll for Ctrl-U and Ctrl-D
set scrolloff=5                                     " Minimal number of screen lines to keep above/below the cursor.
set scrolljump=5                                    " Lines to scroll when cursor leaves screen
set mousehide                                       " Hide mouse while typing
set mouse=a                                         " Enable mouse for all modes
set incsearch                                       " Show match for partly typed search command
set hlsearch                                        " Highlight search
set noscs scs                                       " Uses case insensitive search
set noic ic                                         " override 'ignorecase' when pattern has upper Case
set splitbelow                                      " A new window is put below the current one
set splitright                                      " A new window is put right of the current one
set history=100                                     " Set number of command line history remembered
set directory=~/.config/nvim/tmp/swap                       " Directory for vim swap
set updatetime=4000                                 " Time in ms after which swap will be updated
set updatecount=200                                 " Number of characters typed to cause a swap file update
set undofile                                        " Automatically save and restore undo history
set undodir=~/.config/nvim/tmp/undo                 " Directory for vim undo
set undolevels=1000                                 " Over 1000 levels of undo
set undoreload=10000                                " Maximum number lines to save for undo on a buffer reload
set backup                                          " Enable backup
set backupdir=~/.config/nvim/tmp/backup                     " Set backup dir
set showmatch                                       " When inserting bracket, briefly jump to its match
set number                                          " Show line number for each line
set cursorline                                      " Show cursor line
set fillchars+=vert:\                               " Remove ugly | in split
set laststatus=2
set shortmess=filmnrxoOtT                           " Show short message to avoid hit-enter
set whichwrap=b,s,h,l,<,>,[,]                       " Backspace and cursor keys wrap too
set viewoptions=folds,options,cursor,unix,slash     " Better Unix / Windows compatibility
set iskeyword-=.                                    " '.' is an end of word designator
set list                                            " Useful to see difference between tab and space
set listchars=tab:›\ ,trail:•,extends:#,nbsp:.      " Highlight problematic whitespace
set wildmode=longest,list,full
set wildmenu
" List of file patterns ignored while expanding wildcards
set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.yardoc/*,*/js-build/*,*/node_modules/*,*.exe,*.so,*.dat,*.o,*.obj,*.pyc
set wildignorecase                                  " Ignore case when completing file names

set viminfo+=n~/.config/nvim/tmp/viminfo                " Put viminfo inside .vim/tmp folder

" FORMATTING
set backspace=indent,eol,start                      " Smart backspace
set tabstop=4                                       " Number of spaces a <Tab> in text stands for
set shiftwidth=4                                    " Number of spaces used for each step of indent
set smarttab                                        " a <Tab> is an indent inserts 'shiftwidth' spaces
set expandtab                                       " Set <Tab> to spaces in Insert mode
set softtabstop=4                                   " number of spaces to insert for a <Tab>
set autoindent                                      " Auto indentation
set smartindent                                     " Do clever auto indentation
set nowrap                                          " Don't wrap long lines
set clipboard+=unnamedplus                           "vim uses system clipboard to copy/paste
set splitbelow                                      "split below
set splitright
set title
set titlestring=%m\ %F

" Map leader to ,
let mapleader = ','

function! s:get_visual_selection()
    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end, column_end] = getpos("'>")[1:2]
    let lines = getline(line_start, line_end)
    if len(lines) == 0
        return ''
    endif
    let lines[-1] = lines[-1][: column_end - 1]
    let lines[0] = lines[0][column_start - 1:]
    return join(lines, "\n")
endfunction

function CopyToWclip() range
  echo system("echo -n ".shellescape(s:get_visual_selection())." | wl-copy --type text/plain")
endfunction

if filereadable(expand('~/.vimrc_background'))
    let base16colorspace=256
    source ~/.vimrc_background
    if g:colors_name[7:] == $BASE16_NIGHT_THEME[7:]
        let $FZF_DEFAULT_OPTS=''
    else
        let $FZF_DEFAULT_OPTS=$FZF_THEME_CONFIG
    endif
endif

set termguicolors
let lightlineP="one"

source $HOME/.config/nvim/mapping.vimrc
source $HOME/.config/nvim/lightline.vimrc

let g:fzf_action = {
    \ 'ctrl-t': 'tab split',
    \ 'ctrl-x': 'split',
    \ 'ctrl-v': 'vsplit'
\}

" Indent
let g:indentLine_setColors = 1
let g:indentLine_char = '┆'
let g:indentLine_concealcursor = ''
let g:indentLine_conceallevel = 1
let g:indentLine_fileTypeExclude=['tex', 'json', 'fzf']

" js
let g:ale_linters = {
    \   'javascript': ['eslint'],
    \   'scss': ['scsslint'],
    \   'go': ['gofmt', 'govet', 'revive', 'golangserver'],
    \   'python': ['flake8', 'mypy', 'pylint', 'pyls'],
\}

let g:ale_javascript_eslint_executable = 'eslint_d'
" let g:ale_python_auto_pipenv = 1
let g:jsx_ext_required = 0
let g:ale_go_golangci_lint_package = 1

" Change error symbols
let g:ale_sign_error = '🤣'
let g:ale_sign_warning = '😂'

" Check on file open
let g:ale_lint_on_enter = 1
let g:ale_lint_on_save = 1

" No check on file save
let g:ale_lint_on_save = 0

" Check on text change
let g:ale_lint_on_text_changed = 1
let g:ale_lint_delay = 300 " ms
let g:ale_completion_enabled = 0


" ALE Autocomplete
" let g:ale_completion_enabled = 1
" let g:ale_completion_tsserver_autoimport = 1

"NerdTree ignore
let NERDTreeIgnore = ['\.pyc$']
let NERDTreeMinimalUI = 1
let NERDTreeDirArrows = 1
lua vim.api.nvim_set_var("chadtree_settings", {["keymap.secondary"] = {"<2-leftmouse>"}})

let g:esearch = {
 \            'adapter':    'rg',
 \            'backend':    'system',
 \            'out':        'qflist',
 \            'batch_size': 1000,
 \            'prefill': ['cword', 'hlsearch', 'last', 'clipboard'],
 \           }

let esearch#cmdline#help_prompt = 0

command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --hidden --ignore-case --no-heading --color=always '.shellescape(<q-args>), 1,
  \   <bang>0 ? fzf#vim#with_preview({'options': '--delimiter : --nth 4..'}, 'up:60%')
  \           : fzf#vim#with_preview({'options': '--delimiter : --nth 4..'}, 'right:50%:hidden', '?'),
  \   <bang>0)

command! -bang -nargs=? -complete=dir Files
  \ call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>0)

"Spelunker config
let g:enable_spelunker_vim = 1
let g:spelunker_target_min_char_len = 3
let g:spelunker_disable_auto_group = 1
augroup spelunker
  autocmd!
  autocmd BufWinEnter,BufWritePost *.ts,*.tsx,*.vim,*.js,*.jsx,*.json,*.md call spelunker#check()
  " autocmd CursorHold *.ts,*.tsx,*.vim,*.js,*.jsx,*.json,*.md call spelunker#check_displayed_words()
augroup END

" vim-devicons
let g:webdevicons_enable_nerdtree = 1
let g:webdevicons_enable_startify = 1

" Avoid unwanted square brackets on source vimrc
if exists("g:loaded_webdevicons")
    call webdevicons#refresh()
endif

" ALE Revive
call ale#linter#Define('go', {
\   'name': 'revive',
\   'output_stream': 'both',
\   'executable': 'revive',
\   'read_buffer': 0,
\   'command': 'revive %t',
\   'callback': 'ale#handlers#unix#HandleAsWarning',
\})

hi ALEWarningSign ctermbg=None cterm=None ctermfg=220
hi ALEErrorSign ctermbg=None cterm=None ctermfg=160
hi ALEWarning ctermbg=None cterm=strikethrough ctermfg=None
hi ALEError ctermbg=None cterm=strikethrough ctermfg=None

lua << EOF
    -- Find and use virtualenv via poetry in workspace directory.
    local path = require('lspconfig/util').path
    local function get_python_path(workspace)
        local match = vim.fn.glob(path.join(workspace, 'poetry.lock'))
        if match ~= '' then
          local venv = vim.fn.trim(vim.fn.system('poetry env info -p'))
          return path.join(venv, 'bin', 'python')
        end
    end


    local nvim_lsp = require('lspconfig')
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
      buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
      buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
      buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
      buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
      buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
      buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
      buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
      buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
      buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
      buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
      buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
      buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
      buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
      buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
      buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)

    end

    -- Use a loop to conveniently call 'setup' on multiple servers and
    -- map buffer local keybindings when the language server attaches
    local servers = { "rust_analyzer", "tsserver", "dockerls" }
    for _, lsp in ipairs(servers) do
      nvim_lsp[lsp].setup {
        on_attach = on_attach,
        flags = {
          debounce_text_changes = 150,
        }
      }
    end
    nvim_lsp["pyright"].setup {
        on_attach = on_attach,
        flags = {
          debounce_text_changes = 150,
        },
        before_init = function(_, config)
          config.settings.python.pythonPath = get_python_path(config.root_dir)
        end
    }
EOF

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
