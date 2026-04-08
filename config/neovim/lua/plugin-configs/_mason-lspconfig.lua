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

require('mason-lspconfig').setup {
    automatic_enable = servers,
    ensure_installed = servers,
}
