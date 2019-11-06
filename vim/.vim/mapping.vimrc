" nice navigation in splits
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" FZF Configs
nmap <C-P> :Files <CR>
nmap <c-c> :Commands<CR>
imap <c-x><c-l> <plug>(fzf-complete-line)
nmap <leader>bs :History<cr>                " Search Files History
nmap <leader>bh :History:<cr>               " Search Command History
nmap <leader>cc :Colors<cr>
nmap <leader>fa :Rg!<cr>
nmap ; :Buffers<CR>

" Delete Buffer withouting impacting splits
nmap <leader>q :BD<cr>

" paste without overwriting the buffer
map <leader>p c<C-R>0<Esc>

" map <leader>y :call CopyToWclip()<cr>


"Quickly edit/reload the vimrc file
nmap <silent> <leader>e :e $MYVIMRC<CR>
nmap <silent> <leader>s :so $MYVIMRC<CR>

" Change Working Directory to that of the current file
cmap cd. cd %:p:h

" For when you forget to sudo
cmap w!! w !sudo tee %

" set foldmenthod indent
cmap f!! setlocal foldmethod=indent

" turn off search highlight
nnoremap <leader><space> :nohlsearch<CR>

" space open/closes folds
nnoremap <space> za

" Cd to open file directory
nnoremap ,cd :cd %:p:h<CR>

" Move to next/previous errors
nmap <silent> <leader>k <Plug>(ale_previous_wrap)
nmap <silent> <leader>j <Plug>(ale_next_wrap)

"NerdTree ignore
nmap <leader>n :NERDTreeFind <CR>
noremap <tab> :NERDTreeToggle <CR>

inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<cr>"
