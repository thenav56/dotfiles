call plug#begin()

Plug 'junegunn/fzf.vim'
Plug 'lambdalisue/suda.vim'                 " Ask pass when needed
Plug 'sheerun/vim-polyglot'                 " A solid language packs for vim
Plug 'itchyny/lightline.vim'
Plug 'ms-jpq/chadtree', {'branch': 'chad', 'do': 'python3 -m chadtree deps'}

" Visual (Fonts)
Plug 'ryanoasis/vim-devicons'               " Icons
Plug 'adelarsq/vim-emoji-icon-theme'

call plug#end()

" GENERAL
set synmaxcol=250                                   " syntax highlighting line size limit
set nocompatible                                    " Don't behave very Vi compatible
set encoding=UTF-8                                  " Set character encoding
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
set updatetime=4000                                 " Time in ms after which swap will be updated
set updatecount=200                                 " Number of characters typed to cause a swap file update
set undofile                                        " Automatically save and restore undo history
set undolevels=1000                                 " Over 1000 levels of undo
set undoreload=10000                                " Maximum number lines to save for undo on a buffer reload
set backup                                          " Enable backup
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

" Directories
set undodir=~/.vim/tmp/undo//                          " Directory for vim undo
set backupdir=~/.vim/tmp/backup//                      " Set backup dir
set directory=~/.vim/tmp/swap//                        " Directory for vim swap
set viminfo+=n~/.vim/tmp/viminfo                     " Put viminfo inside .vim/tmp folder

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
set clipboard+=unnamedplus                          "vim uses system clipboard to copy/paste
set splitbelow                                      "split below
set splitright
set title
set titlestring=%m\ %F

lua vim.api.nvim_set_var("chadtree_settings", {["keymap.secondary"] = {"<2-leftmouse>"}})
lua vim.api.nvim_set_var("lightline", {["colorscheme"] = "one"})

source $HOME/.config/nvim/mapping.vimrc
