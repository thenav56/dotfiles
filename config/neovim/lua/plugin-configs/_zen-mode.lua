local zen_mode = require('zen-mode')

zen_mode.setup({
    window = {
       width = 80, -- width of the Zen window
       options = {
         number = false, -- disable number column
       },
     },
    plugins = {
        -- disable some global vim options (vim.o...)
        -- comment the lines to not apply the options
        options = {
            enabled = true,
            ruler = false, -- disables the ruler text in the cmd line area
            -- showcmd = false, -- disables the command in the last line of the screen
            laststatus = 0, -- turn off the statusline in zen mode
        },
        twilight = { enabled = true }, -- enable to start Twilight when zen mode opens
        gitsigns = { enabled = false }, -- disables git signs
        kitty = {
            enabled = false,
            font = "+4", -- font size increment
        },
    }
})
