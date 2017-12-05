call plug#begin('~/.vim/plugged')

Plug 'christoomey/vim-tmux-navigator'
Plug 'airblade/vim-gitgutter'

" Plug 'NLKNguyen/papercolor-theme'

Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

Plug 'w0rp/ale'
Plug 'Konfekt/FastFold'
Plug 'Yggdroot/indentLine'

" Plug 'haya14busa/incsearch.vim'

" Plug 'pangloss/vim-javascript'
" Plug 'jelera/vim-javascript-syntax'
" Plug 'othree/javascript-libraries-syntax.vim'
" Plug 'mxw/vim-jsx'

" Plug 'justinmk/vim-dirvish'
" Plug 'ctrlpvim/ctrlp.vim'
" Plug 'eugen0329/vim-esearch'

" Colorschemes
" Plug 'altercation/vim-colors-solarized'
" Plug 'joshdick/onedark.vim'
Plug 'morhetz/gruvbox'
" Plug 'zeis/vim-kolor'
" Plug 'jpo/vim-railscasts-theme'
" Plug 'rakr/vim-two-firewatch'
" Plug 'rakr/vim-one'

" Plug 'Shougo/vimfiler.vim'
" Plug 'Shougo/unite.vim'
" Plug 'Shougo/vimproc.vim', {'do' : 'make'}

" Plug 'thaerkh/vim-workspace'
" Plug 'Shougo/denite.nvim'
" Plug 'tpope/vim-surround' "gs'}
" Plug 'maralla/completor.vim'

" MISC
" Plug 'xolox/vim-session'
" Plug 'xolox/vim-misc'

" Plug 'tmhedberg/matchit'
" Plug 'tpope/vim-commentary' "gc

" Plug 'rudes/vim-java'

" Plug 'mhinz/vim-signify'
" Plug 'Shougo/unite.vim'
" Plug 'devjoe/vim-codequery'

" MOTION
" Plug 'tpope/vim-vinegar'
" Plug 'scrooloose/nerdtree'
" Plug 'easymotion/vim-easymotion'

" EYECANDY
" Plug 'jacoborus/tender.vim'
" Plug 'gmist/vim-palette'
" Plug 'altercation/vim-colors-solarized'


" Plug 'itchyny/lightline.vim'
" Plug 'shinchu/lightline-gruvbox.vim'
" Plug 'thaerkh/vim-indentguides'

" Plug 'nathanaelkane/vim-indent-guides'
" Plug 'yuttie/comfortable-motion.vim'

" SYNTAX
Plug 'sheerun/vim-polyglot'
" Plug 'Chiel92/vim-autoformat'
" Plug 'Valloric/YouCompleteMe':
" Plug 'terryma/vim-multiple-cursors'

" JAVASCRIPT
" Plug 'ternjs/tern_for_vim'

" REACT

" GIT
" Plug 'Xuyuanp/nerdtree-git-plugin'
" Plug 'airblade/vim-gitgutter'
" Plug 'tpope/vim-fugitive'

" ANGULAR
" Plug 'burnettk/vim-angular'
" Plug 'matthewsimo/angular-vim-snippets'

" PYTHON
"Plug 'klen/python-mode'

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
set colorcolumn=80                                  " Draw indicator column at 80
set nowrap                                        " Don't wrap long lines
" set wrap                                            " Set wrap
" set wrapmargin=10                                 " Number of characters from right window border where wrapping starts
" set synmaxcol=100                                  " Syntax highlighting limit for column
" set textwidth=100                                  " Set maximum width of text that is being inserted
set breakindent                                     " Preseve indent on wrap
set showbreak=...                                   " Wrap indicator
" set conceallevel=0                                  " Do not conceal
" set concealcursor=""

" UI
" let g:onedark_termcolors=256
let g:gruvbox_termcolors = 256
" let g:solarized_termcolors=256

if has('gui_running')
    " set guifont=Fantasque\ Sans\ Mono\ Regular\ 11
    " set guifont=M+\ 1m\ regular\ 11
    set guifont=Iosevka\ Regular\ 11
    set guioptions -=m                              " Remove menubar
    set guioptions -=T                              " Remove GUI toolbar
    set guioptions -=l                              " Remove left-hand scroll bar
    set guioptions -=r                              " Remove right-hand scroll bar
    set guioptions -=L                              " Remove left-hand scroll bar
    set guioptions -=R                              " Remove left-hand scroll bar
else
    set t_Co=256                                    " Set terminal color to 256
endif

set background=dark" Set dark background
colorscheme gruvbox " Set colorscheme
" colorscheme one " Set colorscheme
" colorscheme PaperColor

set showmatch                                       " When inserting bracket, briefly jump to its match
set number                                          " Show line number for each line
set nocursorline                                      " No cursor line
set fillchars+=vert:\                               " Remove ugly | in split
if has('statusline')
    set laststatus=2                                    " Always have a status line
    set statusline=\ %<%f                               " Filename
    set statusline+=%w%h%m%r\                           " Options
    set statusline+=»\ %{&ff}/%Y\                       " Filetype
    " set statusline+=»\ %{getcwd()}\                     " Current directory
    set statusline+=%=%l,%c%V\ %p%%                     " Right aligned file navigation info
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
set wildignore=*.o,*.obj,*/.git/*,*/node_modules,*/bower_components,*/dist " List of file patterns ignored while expanding wildcards
set wildignorecase                                  " Ignore case when completing file names


" Set Folding
hi Folded cterm=italic term=italic ctermfg=242 ctermbg=235 guifg=#666666 guibg=#282828
" hi Folded term=italic cterm=italic ctermfg=244 ctermbg=255
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

" Auto reload config
augroup reload_vimrc " {
    autocmd!
    autocmd BufWritePost $MYVIMRC source $MYVIMRC
augroup END " }

" MAPPINGS

" Open file under cursor
nnoremap gf :vertical wincmd f<CR>

" Map leader to ,
let mapleader = ','

" Quickly edit/reload the vimrc file
nmap <silent> <leader>e :e $MYVIMRC<CR>
nmap <silent> <leader>r :source $MYVIMRC<CR>

" Change Working Directory to that of the current file
cmap cd. cd %:p:h

" For when you forget to sudo
cmap w!! w !sudo tee % >/dev/null

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
nnoremap <leader>F :Rg 

" PLUGINS

" Jsx
let g:jsx_ext_required = 0

" Change indent line
let g:indentLine_char = '▏'

let g:netrw_liststyle = 3
let g:netrw_banner = 0
let g:netrw_browse_split = 4
let g:netrw_winsize = 25

" Fuzzy
let g:rg_command = '
  \ rg --column --line-number --no-heading --fixed-strings --ignore-case
  \ --no-ignore --hidden --follow --color "always"
  \ -g "*.{js,json,php,md,styl,jade,html,config,py,cpp,c,go,hs,rb,conf}"
  \ -g "!{.git,node_modules,vendor,.cache,public}/*" '

command! -bang -nargs=* Rg call fzf#vim#grep(
  \ g:rg_command .shellescape(<q-args>), 1, <bang>0
  \ )


" Ale
let g:ale_sign_column_always = 1
let g:ale_sign_error = '>>'
let g:ale_sign_warning = '> '
let g:ale_linters = { 'javascript': ['eslint'], 'python': ['flake8'], 'scss': ['scsslint'] } " jshint
let g:ale_javascript_eslint_executable = 'eslint_d'
let g:ale_lint_on_enter = 1
let g:ale_lint_on_save = 0
let g:ale_lint_on_text_changed = 1
let g:ale_lint_delay = 50 " ms
" nmap <silent> <C-k> <Plug>(ale_previous_wrap)
" nmap <silent> <C-j> <Plug>(ale_next_wrap)

" CtrlP
" let g:ctrlp_working_path_mode = 'rw'
" Using ag for faster load
" if executable('ag')
"     let g:ctrlp_user_command = 'ag %s -i --nocolor --nogroup --hidden
"         \ --skip-vcs-ignores
"         \ --ignore .git
"         \ --ignore .cache
"         \ --ignore bower_components
"         \ --ignore node_modules
"         \ --ignore "*.tmp"
"         \ --ignore "*.swp"
"         \ --ignore "*.o"
"         \ --ignore "*.obj"
"         \ --ignore "*.pyc"
"         \ --ignore "*~"
"         \ -g ""'
"     let g:ctrlp_cache_dir = $HOME . '/.vim/tmp/cache/ctrlp'
" endif

" let g:dirvish_mode = ':sort ,^.*[\/], | silent keeppatterns g@\v/\.[^\/]+/?$@d _'

" let g:signify_vcs_list = [ 'git' ]
" let g:signify_realtime = 1


" let g:gitgutter_highlight_lines = 1
let g:gitgutter_realtime = 1
let g:gitgutter_= 1



" CTRL-A CTRL-Q to select all and build quickfix list

function! s:build_quickfix_list(lines)
  call setqflist(map(copy(a:lines), '{ "filename": v:val }'))
  copen
  cc
endfunction

let g:fzf_action = {
  \ 'ctrl-q': function('s:build_quickfix_list'),
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }

let $FZF_DEFAULT_OPTS = '--bind ctrl-a:select-all'


" map /  <Plug>(incsearch-forward)
" map ?  <Plug>(incsearch-backward)
" map g/ <Plug>(incsearch-stay)


" >>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FOR GIT <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
" Put this in your .vimrc and whenever you `git commit` you'll see the diff of your commit next to your commit message.
" For the most accurate diffs, use `git config --global commit.verbose true`

" BufRead seems more appropriate here but for some reason the final `wincmd p` doesn't work if we do that.
autocmd VimEnter COMMIT_EDITMSG call OpenCommitMessageDiff()
function! OpenCommitMessageDiff()
  " Save the contents of the z register
  let old_z = getreg("z")
  let old_z_type = getregtype("z")

  try
    call cursor(1, 0)
    let diff_start = search("^diff --git")
    if diff_start == 0
      " There's no diff in the commit message; generate our own.
      let @z = system("git diff --cached -M -C")
    else
      " Yank diff from the bottom of the commit message into the z register
      :.,$yank z
      call cursor(1, 0)
    endif

    " Paste into a new buffer
    vnew
    normal! V"zP
  finally
    " Restore the z register
    call setreg("z", old_z, old_z_type)
  endtry

  " Configure the buffer
  set filetype=diff noswapfile nomodified readonly
  silent file [Changes\ to\ be\ committed]

  " Get back to the commit message
  wincmd p
endfunction
