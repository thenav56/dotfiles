call plug#begin('~/.config/nvim/plugged')

" Visual
Plug 'chriskempson/base16-vim'
Plug 'Yggdroot/indentLine'
Plug 'lambdalisue/suda.vim'

" Git
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

" Quickfix
Plug 'AndrewRadev/qftools.vim'
Plug 'yssl/QFEnter'

" Navigation
Plug 'justinmk/vim-dirvish'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

" Language support
Plug 'sheerun/vim-polyglot'
Plug 'w0rp/ale'
Plug 'autozimu/LanguageClient-neovim', {
    \ 'branch': 'next',
    \ 'do': 'bash install.sh',
    \ }

call plug#end()

filetype plugin indent on
syntax on

" GENERAL
set lazyredraw                                      " Don't draw while executing macros
set hidden                                          " Don't unload a buffer when no longer show in window
set foldlevel=99
set foldmethod=indent                               " Set type of fold (syntax, indent)
set nospell                                         " Disable spell correction
set scroll=11                                       " Number of lines to scroll for Ctrl-U and Ctrl-D
set scrolloff=5                                     " Minimal number of screen lines to keep above/below the cursor.
set scrolljump=5                                    " Lines to scroll when cursor leaves screen
set mouse=a                                         " Enable mouse for all modes
set ignorecase                                      " Uses case insensitive search
set smartcase
set splitbelow                                      " A new window is put below the current one
set splitright                                      " A new window is put right of the current one
set directory=~/.config/nvim/tmp/swap,/tmp                  " Directory for vim swap
set undofile                                        " Automatically save and restore undo history
set undodir=~/.config/nvim/tmp/undo,/tmp                    " Directory for vim undo
set backup                                          " Enable backup
set backupdir=~/.config/nvim/tmp/backup,/tmp                " Set backup dir
set viminfo+=n~/.config/nvim/tmp/viminfo                    " Put viminfo inside .vim/tmp folder

" FORMATTING
set tabstop=4                                       " Number of spaces a <Tab> in text stands for
set shiftwidth=4                                    " Number of spaces used for each step of indent
set softtabstop=4                                   " number of spaces to insert for a <Tab>
set expandtab                                       " Set <Tab> to spaces in Insert mode
set smartindent                                     " Do clever auto indentation
set whichwrap=b,s,h,l,<,>,[,]                       " Backspace and cursor keys wrap too
set nowrap                                          " Don't wrap long lines
set breakindent                                     " Preserve indent on wrap
set showbreak=…                                     " Wrap indicator

" UI
augroup my_colors
  autocmd!
  autocmd ColorScheme * highlight Folded guibg=NONE ctermbg=NONE cterm=italic
augroup END

if has('gui_running')
  set guifont=Anonymous\ Pro\ Regular\ 11
  set guioptions -=m                              " Remove menubar
  set guioptions -=T                              " Remove GUI toolbar
  set guioptions -=l                              " Remove left-hand scroll bar
  set guioptions -=r                              " Remove right-hand scroll bar
  set guioptions -=L                              " Remove left-hand scroll bar
  set guioptions -=R                              " Remove left-hand scroll bar
elseif filereadable(expand('~/.vimrc_background'))
  let base16colorspace=256
  source ~/.vimrc_background
endif

if has('statusline')
  set statusline=\ %<%f                               " Filename
  set statusline+=%w%h%m%r\                           " Options
  set statusline+=»\ %{&ff}/%Y\                       " Filetype
  set statusline+=%=%l,%c%V\ %3p%%\ %L                " Right aligned file navigation info

endif
if has('cmdline_info')
  set rulerformat=%30(%=\:b%n%y%m%r%w\ %l,%c%V\ %P%)  " A ruler on steroids
endif

set showmatch                                       " When inserting bracket, briefly jump to its match
set number                                          " Show line number for each line
set fillchars+=vert:\                               " Remove ugly | in split
set shortmess=filmnrxoOtT                           " Show short message to avoid hit-enter
set viewoptions=folds,options,cursor,unix,slash     " Better Unix / Windows compatibility
set iskeyword-=.                                    " '.' is an end of word designator
set list                                            " Useful to see difference between tab and space
set listchars=tab:›\ ,trail:•,extends:#,nbsp:.      " Highlight problematic whitespace
set wildmode=list:longest                           " Specifies how command line completion works
set wildignore=*.o,*.obj,*/.git/*,*/node_modules,*/coverage/,*/bower_components,*/dist,__pycache__,env " List of file patterns ignored while expanding wildcards
set wildignorecase                                  " Ignore case when completing file names

" PLUGINS

" Indent line
let g:indentLine_char = '▏'

" Language Server
let g:LanguageClient_serverCommands = {
\ 'python': ['pyls'],
\ 'javascript.jsx': ['javascript-typescript-stdio'],
\ 'javascript': ['javascript-typescript-stdio'],
\ 'typescript': ['javascript-typescript-stdio'],
\ }
let g:LanguageClient_autoStart = 1
let g:LanguageClient_diagnosticsList = 'Disabled'

" Ale
let g:ale_sign_column_always = 1
let g:ale_linters_explicit = 1
let g:ale_sign_error = '>>'
let g:ale_sign_warning = '> '
let g:ale_linters = {
  \ 'vim': ['vint'],
  \ 'typescript': ['tslint'],
  \ 'javascript.jsx': ['eslint'],
  \ 'javascript': ['eslint'],
  \ 'python': ['flake8'],
  \ 'scss': ['stylelint'],
  \ 'css': ['stylelint']
  \ }
let g:ale_fixers = {
  \ 'vim': ['vint'],
  \ 'scss': ['stylelint'],
  \ 'css': ['stylelint'],
  \ 'typescript': ['tslint'],
  \ 'javascript.jsx': ['eslint'],
  \ 'javascript': ['eslint'],
  \ }
let g:ale_javascript_eslint_executable = 'eslint_d'
let g:ale_lint_on_enter = 1
let g:ale_lint_on_save = 0
let g:ale_lint_on_text_changed = 1
let g:ale_lint_delay = 150 " ms

" Git Gutter
let g:gitgutter_realtime = 1
let g:gitgutter_= 1

" Dirvish
let g:dirvish_mode = 1
augroup dirvish
  autocmd!
  autocmd FileType dirvish silent sort '^.*[\/]'
  autocmd FileType dirvish silent keeppatterns g@\v/\.[^\/]+/?$@d _
  autocmd FileType dirvish silent! unmap <buffer> <C-p>
augroup END

" Netrw
let g:loaded_netrw = 1              " disable
let g:loaded_netrwPlugin = 1

" MAPPINGS
" Map leader to ,
let mapleader = ','
let maplocalleader = '\\'

" For when you forget to sudo
cnoremap w!! w !sudo tee % >/dev/null

" smart navigation even on wrapped lines
noremap <silent> <expr> j (v:count == 0 ? 'gj' : 'j')
noremap <silent> <expr> k (v:count == 0 ? 'gk' : 'k')

" Quickly edit/reload the vimrc file
nnoremap <silent> <leader>c :e $MYVIMRC<CR>
nnoremap <silent> <leader>r :source $MYVIMRC<CR>

" Open file explorer
nnoremap <leader>e :call dirvish#open(getcwd()) <cr>
nnoremap <leader>E :Dirvish % <cr>

" Change working directory to that of the current file
cnoremap cd. cd %:p:h

" Fzf related bindings
nnoremap <leader>f :Files<CR>
nnoremap <leader>F :Rg -e 
nnoremap <leader>W :RgWord<CR>

" CUSTOM FOLD
function! MyFoldText() " {{{
  let line = getline(v:foldstart)

  let nucolwidth = &foldcolumn + &number * &numberwidth
  let windowwidth = winwidth(0) - nucolwidth - 3
  let foldedlinecount = v:foldend - v:foldstart

  " expand tabs into spaces
  let onetab = strpart('          ', 0, &tabstop)
  let line = substitute(line, '\t', onetab, 'g')

  let line = strpart(line, 0, windowwidth - 2 -len(foldedlinecount))
  let fillcharcount = windowwidth - len(line) - len(foldedlinecount) - 8
  return line . ' ... ' . foldedlinecount . ' lines' . repeat(' ',fillcharcount)
endfunction " }}}
set foldtext=MyFoldText()

" CTRL-A CTRL-Q to select all and build quickfix list
function! s:build_quickfix_list(lines)
  call setqflist(map(copy(a:lines), '{ "filename": v:val }'), 'r', { 'title': 'My search' })
  copen
  cc
endfunction

" FZF
let g:fzf_action = {
  \ 'ctrl-q': function('s:build_quickfix_list'),
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }
let $FZF_DEFAULT_OPTS = '--bind ctrl-a:select-all'

" FZF search inside text
let g:rg_command = '
  \ rg --column --line-number --no-heading --case-sensitive
  \ --no-ignore --hidden --follow --color "always"
  \ -g "*.{js,jsx,ts,tsx,json,php,md,styl,jade,html,config,py,cpp,c,go,hs,rb,conf,scss,css,html}"
  \ -g "!{.git,coverage,node_modules,vendor,.cache,public,generated,android,ios}/*" '
command! -bang -nargs=* RgWord call fzf#vim#grep(
  \ g:rg_command .shellescape(expand('<cword>')), 1, <bang>0
  \ )
command! -bang -nargs=* Rg call fzf#vim#grep(
  \ g:rg_command .<q-args>, 1, <bang>0
  \ )
