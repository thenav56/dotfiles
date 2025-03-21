local ufo = require("ufo")

vim.opt.foldcolumn = '1' -- '0' is not bad
vim.opt.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
vim.opt.foldlevelstart = 3
vim.opt.foldenable = true

vim.keymap.set('n', 'zR', ufo.openAllFolds)
vim.keymap.set('n', 'zM', ufo.closeAllFolds)
vim.keymap.set('n', 'zr', ufo.openFoldsExceptKinds)
vim.keymap.set('n', 'zm', ufo.closeFoldsWith) -- closeAllFolds == closeFoldsWith(0)

local ftMap = {
    vim = 'indent',
    python = {'indent'},
    git = ''
}


ufo.setup({
    open_fold_hl_timeout = 150,
    close_fold_kinds_for_ft = {
        default = {'imports', 'comment'},
        json = {'array'},
        c = {'comment', 'region'}
    },
    provider_selector = function(bufnr, filetype, buftype)
        return ftMap[filetype] or {'treesitter', 'indent'}
    end
})
