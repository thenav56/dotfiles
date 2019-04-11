let g:lightline = {
 \            'colorscheme': g:lightlineP,
 \            'inactive': {
 \              'left': [ [], [ 'readonly', 'filename', 'modified' ] ],
 \              'right': [ ['lineinfo'], ['percent'] ],
 \            },
 \            'active': {
 \              'left': [ [ 'mode', 'paste' ], [ 'gitbranch', 'readonly', 'filename', 'modified' ] ],
 \              'right': [ ['lineinfo'], ['percent'],
 \                         [ 'filetype'],
 \                         [ 'linter_warnings', 'linter_errors' ]]
 \            },
 \            'component_function': {
 \              'gitbranch': 'LightlineGitBranch',
 \              'filename': 'LightlineFilename',
 \              'modified': 'LightlineModified',
 \            },
 \            'component_expand': {
 \              'readonly': 'LightlineReadOnly',
 \              'linter_warnings': 'LightlineLinterWarnings',
 \              'linter_errors': 'LightlineLinterErrors',
 \            },
 \            'component_type': {
 \              'readonly': 'error',
 \              'linter_warnings': 'warning',
 \              'linter_errors': 'error',
 \            },
 \            }

autocmd User ALELint call lightline#update()

function! LightlineReadOnly()
    return &readonly ? '' : ''
endfunction

function! LightlineGitBranch()
    return fugitive#head() !=# '' ? 'B: ' . fugitive#head()  : ''
endfunction

function! LightlineFilename()
    return expand('%:') !=# '' ? GetShortPath() . expand('%:t') : '[No Name]'
endfunction

function! LightlineModified()
    return &modified ? '[+]' : ''
endfunction

function! LightlineLinterWarnings() abort
    let l:counts = ale#statusline#Count(bufnr(''))
    let l:all_errors = l:counts.error + l:counts.style_error
    let l:all_non_errors = l:counts.total - l:all_errors
    return l:counts.total == 0 ? '' : printf('%d ', all_non_errors)
endfunction

function! LightlineLinterErrors() abort
    let l:counts = ale#statusline#Count(bufnr(''))
    let l:all_errors = l:counts.error + l:counts.style_error
    let l:all_non_errors = l:counts.total - l:all_errors
    return l:counts.total == 0 ? '' : printf('%d ✗', all_errors)
endfunction

function! GetShortPath()
    let s:is_win = has('win32') || has('win64')
    let short = fnamemodify(expand('%:h'), ':~:.')
    if !has('win32unix')
        let short = pathshorten(short)
    endif
    let slash = (s:is_win && !&shellslash) ? '\' : '/'
    return empty(short) ? '~'.slash : short . (short =~ escape(slash, '\').'$' ? '' : slash)
endfunction

" Update and show lightline but only if it's visible (e.g., not in Goyo)
function! s:MaybeUpdateLightline()
    if exists('#lightline')
        call lightline#update()
    end
endfunction
