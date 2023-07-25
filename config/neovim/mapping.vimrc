nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

nmap <silent> <leader>s :so $MYVIMRC<CR>
nmap <silent> <leader>e :e $MYVIMRC<CR>

noremap <tab> :CHADopen <CR>

let mapleader = ';'
nmap <C-P> :Files <CR>
nmap <leader>bs :History<cr>                        " Search Files History

nmap ; :Buffers<CR>

" Reload neovim config
nnoremap <leader>s :source $MYVIMRC<CR>
