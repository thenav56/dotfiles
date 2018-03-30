call plug#begin('~/.vim/plugged')

Plug 'tpope/vim-surround'
Plug 'sickill/vim-pasta'
Plug 'AndrewRadev/qftools.vim'
" Plug 'tpope/vim-repeat'
" Plug 'troydm/easytree.vim'
" Plug 'xolox/vim-notes'

" Plug 'rakr/vim-one'
Plug 'Yggdroot/indentLine'

Plug 'airblade/vim-gitgutter'

Plug 'justinmk/vim-dirvish'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

Plug 'w0rp/ale'
Plug 'sheerun/vim-polyglot'

Plug 'prabirshrestha/async.vim'
Plug 'prabirshrestha/vim-lsp'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'

call plug#end()

filetype plugin indent on
syntax on

" GENERAL
set nocompatible                                    " Don't behave very Vi compatible
set encoding=utf-8                                  " Set character encoding
set lazyredraw                                      " Don't draw while executing macros
set hidden                                          " Don't unload a buffer when no longer show in window
set foldenable                                      " Set to display all folds open
set foldlevel=99
set foldmethod=indent                               " Set type of fold (syntax, indent)
set foldminlines=1
set remap                                           " Recognize mappings in mapped keys
set nospell                                         " Disable spell correction
set scroll=11                                       " Number of lines to scroll for Ctrl-U and Ctrl-D
set scrolloff=5                                     " Minimal number of screen lines to keep above/below the cursor.
set scrolljump=5                                    " Lines to scroll when cursor leaves screen
set mousehide                                       " Hide mouse while typing
set mouse=a                                         " Enable mouse for all modes
set incsearch                                       " Show match for partly typed search command
set hlsearch                                        " Highlight search
set ignorecase                                      " Uses case insensitive search
set smartcase
set splitbelow                                      " A new window is put below the current one
set splitright                                      " A new window is put right of the current one
set history=100                                     " Set number of command line history remembered
set directory=~/.vim/tmp/swap,/tmp                  " Directory for vim swap
set updatetime=4000                                 " Time in ms after which swap will be updated
set updatecount=200                                 " Number of characters typed to cause a swap file update
set undofile                                        " Automatically save and restore undo history
set undodir=~/.vim/tmp/undo,/tmp                    " Directory for vim undo
set undolevels=1000                                 " Over 1000 levels of undo
set undoreload=10000                                " Maximum number lines to save for undo on a buffer reload
set backup                                          " Enable backup
set backupdir=~/.vim/tmp/backup,/tmp                " Set backup dir
set viminfo+=n~/.vim/tmp/viminfo                    " Put viminfo inside .vim/tmp folder

" FORMATTING
set backspace=indent,eol,start                      " Smart backspace
set tabstop=4                                       " Number of spaces a <Tab> in text stands for
set shiftwidth=4                                    " Number of spaces used for each step of indent
set softtabstop=4                                   " number of spaces to insert for a <Tab>
set smarttab                                        " a <Tab> is an indent inserts 'shiftwidth' spaces
set expandtab                                       " Set <Tab> to spaces in Insert mode
set autoindent                                      " Auto indentation
set smartindent                                     " Do clever auto indentation
set whichwrap=b,s,h,l,<,>,[,]                       " Backspace and cursor keys wrap too
" set colorcolumn=80                                  " Draw indicator column at 80
set nowrap                                          " Don't wrap long lines
" set wrap                                          " Set wrap
" set wrapmargin=10                                 " Number of characters from right window border where wrapping starts
" set synmaxcol=100                                 " Syntax highlighting limit for column
" set textwidth=100                                 " Set maximum width of text that is being inserted
set breakindent                                     " Preseve indent on wrap
set showbreak=…                                     " Wrap indicator
" set conceallevel=0                                " Do not conceal
" set concealcursor=""
set formatoptions+=j                                " Sane line joins

" UI
if has('gui_running')
    set guifont=Anonymous\ Pro\ Regular\ 11
    " set guifont=Fantasque\ Sans\ Mono\ Regular\ 11
    " set guifont=M+\ 1m\ regular\ 11
    " set guifont=Iosevka\ Regular\ 11
    set guioptions -=m                              " Remove menubar
    set guioptions -=T                              " Remove GUI toolbar
    set guioptions -=l                              " Remove left-hand scroll bar
    set guioptions -=r                              " Remove right-hand scroll bar
    set guioptions -=L                              " Remove left-hand scroll bar
    set guioptions -=R                              " Remove left-hand scroll bar
else
    " set t_Co=256                                    " Set terminal color to 256
    " let g:gruvbox_termcolors = 256
    " let g:solarized_termcolors=256
   "  set termguicolors
endif

" set background=light                                " Set dark background
" colorscheme default
" colorscheme one                                     " Set colorscheme

set showmatch                                       " When inserting bracket, briefly jump to its match
set number                                          " Show line number for each line
set nocursorline                                      " No cursor line
set fillchars+=vert:\                               " Remove ugly | in split
if has('statusline')
    set laststatus=2                                    " Always have a status line
    set statusline=\ %<%f                               " Filename
    set statusline+=%w%h%m%r\                           " Options
    set statusline+=»\ %{&ff}/%Y\                       " Filetype
    " set statusline+=»\ %{getcwd()}\                   " Current directory
    set statusline+=%=%l,%c%V\ %3p%%\ %L                 " Right aligned file navigation info
endif
if has('cmdline_info')
    set ruler                                           " Shows current position below each window
    set rulerformat=%30(%=\:b%n%y%m%r%w\ %l,%c%V\ %P%)  " A ruler on steroids
    set showcmd                                         " Show command in the last line of the screen
    set showmode                                        " Show current mode in last line
endif
set shortmess=filmnrxoOtT                           " Show short message to avoid hit-enter
set viewoptions=folds,options,cursor,unix,slash     " Better Unix / Windows compatibility
set iskeyword-=.                                    " '.' is an end of word designator
set list                                            " Useful to see difference between tab and space
set listchars=tab:›\ ,trail:•,extends:#,nbsp:.      " Highlight problematic whitespace
set wildmenu                                        " Command-line completion show a list of matches
set wildmode=list:longest                           " Specifies how command line completion works
set wildignore=*.o,*.obj,*/.git/*,*/node_modules,*/coverage/,*/bower_components,*/dist " List of file patterns ignored while expanding wildcards
set wildignorecase                                  " Ignore case when completing file names

" PLUGINS

" Jsx
let g:jsx_ext_required = 0

" Change indent line
let g:indentLine_char = '▏'

" Ale
let g:ale_sign_column_always = 1
let g:ale_sign_error = '>>'
let g:ale_sign_warning = '> '
let g:ale_linters = { 'javascript': ['eslint'], 'python': ['flake8'], 'scss': ['stylelint'] }
let g:ale_fixers = { 'scss': ['stylelint'], 'javascript': ['eslint'] }
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

" AsyncComplete
let g:asyncomplete_auto_popup = 1
let g:asyncomplete_remove_duplicates = 1

" Lsp
if executable('typescript-language-server')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'typescript-language-server',
        \ 'cmd': {server_info->[&shell, &shellcmdflag, 'typescript-language-server --stdio']},
        \ 'root_uri':{server_info->lsp#utils#path_to_uri(lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), 'tsconfig.json'))},
        \ 'whitelist': ['typescript'],
        \ })
endif

" LSP
let g:lsp_async_completion = 1
autocmd FileType typescript setlocal omnifunc=lsp#complete


" CUSTOM

" CTRL-A CTRL-Q to select all and build quickfix list
function! s:build_quickfix_list(lines)
  call setqflist(map(copy(a:lines), '{ "filename": v:val }'))
  copen
  cc
endfunction

" Fzf
let g:fzf_action = {
  \ 'ctrl-q': function('s:build_quickfix_list'),
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }
let $FZF_DEFAULT_OPTS = '--bind ctrl-a:select-all'

" Fzf search inside text
let g:rg_command = '
  \ rg --column --line-number --no-heading --case-sensitive
  \ --no-ignore --hidden --follow --color "always"
  \ -g "*.{js,jsx,ts,tsx,json,php,md,styl,jade,html,config,py,cpp,c,go,hs,rb,conf,scss,css}"
  \ -g "!{.git,coverage,node_modules,vendor,.cache,public,generated}/*" '
command! -bang -nargs=* RgWord call fzf#vim#grep(
  \ g:rg_command .shellescape(expand('<cword>')), 1, <bang>0
  \ )
command! -bang -nargs=* Rg call fzf#vim#grep(
  \ g:rg_command .<q-args>, 1, <bang>0
  \ )

" FOLDING TEXT
function! MyFoldText() " {{{
    let line = getline(v:foldstart)

    let nucolwidth = &fdc + &number * &numberwidth
    let windowwidth = winwidth(0) - nucolwidth - 3
    let foldedlinecount = v:foldend - v:foldstart

    " expand tabs into spaces
    let onetab = strpart('          ', 0, &tabstop)
    let line = substitute(line, '\t', onetab, 'g')

    let line = strpart(line, 0, windowwidth - 2 -len(foldedlinecount))
    let fillcharcount = windowwidth - len(line) - len(foldedlinecount) - 8
    return line . ' ... ' . foldedlinecount . ' lines' . repeat(" ",fillcharcount)
endfunction " }}}
set foldtext=MyFoldText()


" Set errors
match ErrorMsg '\%>120v.\+'
match ErrorMsg '\s\+$'

" MAPPINGS
" Map leader to ,
let mapleader = ','
let maplocalleader = '\\'

" Open file under cursor
nnoremap gf :vertical wincmd f<CR>

" Open file explorer
nnoremap <leader>e :call dirvish#open(getcwd()) <cr>
nnoremap <leader>E :Dirvish % <cr>

" Quickly edit/reload the vimrc file
nnoremap <silent> <leader>c :e $MYVIMRC<CR>
nnoremap <silent> <leader>r :source $MYVIMRC<CR>

" Change Working Directory to that of the current file
cnoremap cd. cd %:p:h

" For when you forget to sudo
cnoremap w!! w !sudo tee % >/dev/null

" smart navigation even on wrapped lines
noremap <silent> <expr> j (v:count == 0 ? 'gj' : 'j')
noremap <silent> <expr> k (v:count == 0 ? 'gk' : 'k')

" Better motion
nnoremap <c-j> <c-w>j
nnoremap <c-k> <c-w>k
nnoremap <c-h> <c-w>h
nnoremap <c-l> <c-w>l

" Fzf related bindings
nnoremap <leader>f :Files<CR>
nnoremap <leader>F :Rg -e 
nnoremap <leader>W :RgWord<CR>

" function! GetCurrentColorscheme()
"     try
"         return g:colors_name
"     catch /^Vim:E121/
"         return "default"
"     endtry
" endfunction

hi Folded cterm=italic ctermbg=256 ctermfg=249

" function! SetFoldColor()
"     let current_colorscheme = GetCurrentColorscheme()
"     if (current_colorscheme ==# 'PaperColor')
"         if (&background ==# 'light')
"             hi Folded cterm=italic ctermfg=102 ctermbg=255 gui=italic guifg=#878787 guibg=#eeeeee
"         else
"             hi Folded cterm=italic ctermfg=244 ctermbg=234 gui=italic guifg=#808080 guibg=#1c1c1c
"         endif
"     elseif (current_colorscheme ==# 'one')
"         if (&background ==# 'light')
"             hi Folded cterm=italic ctermfg=145 ctermbg=255 gui=italic guifg=#a0a1a7 guibg=#fafafa
"         else
"             hi Folded cterm=italic ctermfg=59 ctermbg=16 gui=italic guifg=#5c6370 guibg=#282c34
"         endif
"         hi SpellBad cterm=underline
"         hi SpellCap cterm=underline
"     elseif (current_colorscheme ==# 'gruvbox')
"         if (&background ==# 'light')
"             hi Folded cterm=italic term=italic ctermfg=242 ctermbg=235 guifg=#666666 guibg=#282828
"         endif
"     endif
" endfunction

" function! ToggleBackground()
"     let &background = ( &background ==# "dark"? "light" : "dark" )
"     call SetFoldColor()
" endfunction

" call SetFoldColor()
" nnoremap <Leader>b :call ToggleBackground()<CR>
