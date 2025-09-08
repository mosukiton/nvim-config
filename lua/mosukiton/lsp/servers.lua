return {
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
    -- roslyn_ls = require "mosukiton.lsp.lspconfig.roslyn",
    basedpyright = {}, -- use lspconfig defaults
    clangd = {}, -- use lspconfig defaults
}
