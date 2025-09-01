return {
    ensure_installed = {
        -- "roslyn", -- TODO uncomment this when roslyn gets added to mason-lspconfig
        "pyright",
        "lua_ls",
        "jsonls",
    },
    automatic_installation = true,
}
