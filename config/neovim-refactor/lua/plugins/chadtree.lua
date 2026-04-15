-- Hook to run after install/update
vim.api.nvim_create_autocmd("PackChanged", { callback = function(ev)
  local name, kind = ev.data.spec.name, ev.data.kind
  if name == "chadtree" and (kind == "update" or kind == "install") then
    if not ev.data.active then vim.cmd.packadd("chadtree") end
    vim.cmd("CHADdeps")
  end
end })

vim.pack.add({
    "https://github.com/adelarsq/vim-emoji-icon-theme",
    "https://github.com/ryanoasis/vim-devicons",
    { src = "https://github.com/ms-jpq/chadtree" , version = "chad" },
})

local chadtree_settings = {
  ["keymap.secondary"] = {"<2-leftmouse>"},
}
vim.api.nvim_set_var("chadtree_settings", chadtree_settings)

-- NOTE: <tab> == ctrl-i (opposite to ctrl+o), so using <leader-tab> instead
-- https://github.com/neovim/neovim/issues/5916
vim.keymap.set('', '<leader><tab>', ':CHADopen<CR>', { silent = true, remap = false })
