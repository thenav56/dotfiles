local M = {}

function M.TrimWhitespace()
    local view = vim.fn.winsaveview()
    vim.api.nvim_exec(
        string.format(
            'keepjumps keeppatterns silent! %s',
            [[%s/\s\+$//e]]
        ),
        false
    )
    vim.fn.winrestview(view)
end

return M
