require('mason-lspconfig').setup {
    automatic_installation = true,
    ensure_installed = {
        "bashls",
        "docker_compose_language_service",
        "dockerls",
        "eslint",
        "graphql",
        "html",
        "jsonls",
        "lua_ls",
        "pyright",
        "pylsp",
        "sqlls",
        "stylelint_lsp",
        "tsserver",
        "yamlls",
    },
}
