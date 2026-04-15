vim.pack.add({ 'https://github.com/akinsho/git-conflict.nvim' })

-- https://github.com/akinsho/git-conflict.nvim
require'git-conflict'.setup {
    default_mappings = true,
    -- co — choose ours
    -- ct — choose theirs
    -- cb — choose both
    -- c0 — choose none
    -- ]x — move to previous conflict
    -- [x — move to next conflict
    default_commands = true, -- disable commands created by this plugin
    -- GitConflictChooseOurs — Select the current changes.
    -- GitConflictChooseTheirs — Select the incoming changes.
    -- GitConflictChooseBoth — Select both changes.
    -- GitConflictChooseNone — Select none of the changes.
    -- GitConflictNextConflict — Move to the next conflict.
    -- GitConflictPrevConflict — Move to the previous conflict.
    -- GitConflictListQf — Get all conflict to quickfix
    disable_diagnostics = false, -- This will disable the diagnostics in a buffer whilst it is conflicted
    list_opener = 'copen', -- command or function to open the conflicts list
    highlights = { -- They must have background color, otherwise the default color will be used
        incoming = 'DiffAdd',
        current = 'DiffText',
    },
}
