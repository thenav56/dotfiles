local ibl = require('ibl')

ibl.setup({
    -- debounce = 2000,
    indent = {
        char = {
            "│",
            "┆",
        },
        tab_char = {
            "█",
            "║",
        }
    },
    scope = {
        enabled = false
    },
    exclude = {
        filetypes = {
            "help",
            "alpha",
            "dashboard",
            "neo-tree",
            "Trouble",
            "trouble",
            "lazy",
            "mason",
            "notify",
            "toggleterm",
            "lazyterm",
        },
    },
})
