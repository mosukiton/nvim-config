local M = {}

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
    lua_ls = require "local.lsp.lspconfig.lua_ls",
    -- roslyn_ls = require "local.lsp.lspconfig.roslyn",
    pyright = {}, -- use lspconfig defaults
    clangd = {}, -- use lspconfig defaults
}


-- require("local.lsp.handlers").setup()
--
-- vim.lsp.config("roslyn", {
--     settings = {
--         ["csharp|inlay_hints"] = {
--             csharp_enable_inlay_hints_for_implicit_object_creation = true,
--             csharp_enable_inlay_hints_for_implicit_variable_types = true,
--         },
--         ["csharp|code_lens"] = {
--             dotnet_enable_references_code_lens = true,
--         },
--     },
-- })
-- vim.lsp.enable("roslyn")


M.config = function ()
    require ("local.lsp.lsp_attach")
    vim.diagnostic.config(require ("local.lsp.diagnostics-opts"))

    -- LSP servers and clients are able to communicate to each other what features they support.
    --  By default, Neovim doesn't support everything that is in the LSP specification.
    --  When you add blink.cmp, luasnip, etc. Neovim now has *more* capabilities.
    --  So, we create new capabilities with blink.cmp, and then broadcast that to the servers.
    local ensure_installed = vim.tbl_keys(servers or {})
    -- require('mason-tool-installer').setup { ensure_installed = ensure_installed }
    local fidget = require("fidget")

    require('mason-lspconfig').setup {
        fidget.notify("setting up mason lspconfig", vim.log.levels.INFO);
        ensure_installed = ensure_installed, -- explicitly set to an empty table (Kickstart populates installs via mason-tool-installer)
        automatic_installation = {
            ensure_installed,
            exclude = {
                "roslyn"
            }
        },
    }

    -- vim.list_extend(ensure_installed, {
    --     'stylua', -- Used to format Lua code
    -- })

    local capabilities = require('blink.cmp').get_lsp_capabilities()

    for server_name in pairs(servers) do
        local server = servers[server_name] or {}
        -- This handles overriding only values explicitly passed
        -- by the server configuration above. Useful when disabling
        -- certain features of an LSP (for example, turning off formatting for ts_ls)
        server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
        require('lspconfig')[server_name].setup(server)
        if (server_name == 'roslyn') then
            fidget.notify("setting up " .. server_name, vim.log.levels.INFO);
        end
    end

    -- enable custom roslyn set up 
    fidget.notify("Setting up roslyn", vim.log.levels.INFO)
    local roslyn = require("local.lsp.lspconfig.roslyn")
    vim.lsp.config("roslyn", roslyn)
    fidget.notify("Enabling up roslyn", vim.log.levels.INFO)
    vim.lsp.enable("roslyn")
end

return M
