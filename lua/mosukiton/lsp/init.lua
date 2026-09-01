local M = {}

---@type table<string, vim.lsp.Config>
local servers = {
    -- Enable the following language servers
    --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
    --
    --  Add any additional override configuration in the following tables. Available keys are:
    --  - cmd (table): Override the default command used to start the server
    --  - filetypes (table): Override the default list of associated filetypes for the server
    --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
    --  - settings (table): Override the default settings passed when initializing the server.
    --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
    lua_ls = require "mosukiton.lsp.lspconfig.lua_ls",
    basedpyright = {}, -- use lspconfig defaults
    clangd = {}, -- use lspconfig defaults
}

---@return nil
M.config = function()
    require("mosukiton.lsp.roslyn_debug").configure_lsp_logging()
    require("mosukiton.lsp.roslyn_debug").setup_commands()

    require ("mosukiton.lsp.lsp_attach")
    vim.diagnostic.config(require ("mosukiton.lsp.diagnostics-opts"))

    -- LSP servers and clients are able to communicate to each other what features they support.
    --  By default, Neovim doesn't support everything that is in the LSP specification.
    --  When you add blink.cmp, luasnip, etc. Neovim now has *more* capabilities.
    --  So, we create new capabilities with blink.cmp, and then broadcast that to the servers.
    ---@type string[]
    local ensure_installed = vim.tbl_keys(servers)

    -- Mason manages these servers. Roslyn is intentionally excluded because
    -- it is installed as the cross-platform .NET global tool.
    require("mason-lspconfig").setup({
        ensure_installed = ensure_installed,
    })

    local capabilities = require('blink.cmp').get_lsp_capabilities()

    for server_name in pairs(servers) do
        local server = servers[server_name] or {}
        -- This handles overriding only values explicitly passed
        -- by the server configuration above. Useful when disabling
        -- certain features of an LSP (for example, turning off formatting for ts_ls)
        server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
        vim.lsp.config(server_name, server)
    end

    -- Merge our command/settings into roslyn.nvim's `roslyn` server config.
    -- The plugin enables the client and supplies root_dir, on_init, handlers, and
    -- commands; without the plugin, only the minimal `roslyn_ls` config exists.
    local roslyn = require("mosukiton.lsp.lspconfig.roslyn")
    vim.lsp.config("roslyn", roslyn)
    require("mosukiton.lsp.roslyn_solution_diagnostics").setup()
end

return M
