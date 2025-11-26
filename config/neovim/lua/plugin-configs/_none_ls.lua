local null_ls = require("null-ls")

local function applyPattern(substitution)
    return function()
        local view = vim.fn.winsaveview()
        vim.api.nvim_exec(
            string.format(
                'keepjumps keeppatterns silent! %s',
                substitution
            ),
            false
        )
        vim.fn.winrestview(view)
    end
end

null_ls.register({
    name = 'custom-actions',
    method = { require 'null-ls'.methods.CODE_ACTION },
    filetypes = { '_all' },
    generator = {
        fn = function()
            return {
                {
                    title = 'cleanTrailingWhitespace',
                    action = applyPattern([[%s/\s\+$//e]]),
                },
                {
                    title = 'envCollonToEqualty',
                    action = applyPattern([[%s/\v(\w+):\s+(.*)/\1=\2]]),
                },
            }
        end
    }
})

-- TODO:
null_ls.setup({
    sources = {
        null_ls.builtins.code_actions.gitsigns,
        null_ls.builtins.formatting.prettier,
        null_ls.builtins.formatting.mix,
        null_ls.builtins.formatting.rubocop,
        null_ls.builtins.diagnostics.rubocop,
        -- null_ls.builtins.diagnostics.shellcheck
    }
})
