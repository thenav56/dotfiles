-- Hook to run after install/update
vim.api.nvim_create_autocmd("PackChanged", { callback = function(ev)
  local name, kind = ev.data.spec.name, ev.data.kind
  if name == "mason" and (kind == "update" or kind == "install") then
    if not ev.data.active then vim.cmd.packadd("mason") end
    vim.cmd("MasonUpdate")
  end
end })


vim.pack.add({
  "https://github.com/williamboman/mason.nvim",
  "https://github.com/williamboman/mason-lspconfig.nvim",
})

-- https://mason-registry.dev/registry/list
local servers = {
    "bashls",
    "docker_compose_language_service",
    "dockerls",
    "eslint",
    "graphql",
    "html",
    "jsonls",
    "lua_ls",
    "pyright",
    "ruff",
    "sqlls",
    "stylelint_lsp",
    "ts_ls",
    "yamlls",
    "tflint",
    "terraformls",
    "harper_ls",
    "gh_actions_ls",
    "postgres_lsp",
    -- Not working anymore
    -- "nginx_language_server",
}

require('mason').setup()

require('mason-lspconfig').setup {
    automatic_enable = true,
    ensure_installed = servers,
}
