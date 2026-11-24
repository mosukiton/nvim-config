-- Single source of truth for every third-party package version this config installs.
--
-- Plugins are pinned to full commit SHAs (tags and branches can be moved, a SHA cannot).
-- `mosukiton.plugins` refuses to start if a plugin spec has no entry here, so a new
-- plugin can't be added without also pinning it. To upgrade a plugin: review the
-- upstream diff between the old and new SHA, change the SHA here, then run
-- `:Lazy update <name>`; that checks out the new SHA and rewrites `lazy-lock.json`.
-- (`:Lazy update` never moves a plugin past its pin, and `:Lazy restore` goes back to
-- the lockfile, so keep the two in sync and commit them together.)
--
-- Last audited: 2026-11-24 (see the security audit report for details).

local M = {}

---@type table<string, string> "owner/repo" -> commit SHA
M.plugins = {
    ["folke/lazy.nvim"]                            = "306a05526ada86a7b30af95c5cc81ffba93fef97", -- stable+4
    ["nvim-lua/plenary.nvim"]                      = "74b06c6c75e4eeb3108ec01852001636d85a932b",
    ["lukas-reineke/indent-blankline.nvim"]        = "d28a3f70721c79e3c5f6693057ae929f3d9c0a03", -- v3.9.1
    ["folke/tokyonight.nvim"]                      = "cdc07ac78467a233fd62c493de29a17e0cf2b2b6",
    ["folke/lazydev.nvim"]                         = "ff2cbcba459b637ec3fd165a2be59b7bbaeedf0d",
    ["neovim/nvim-lspconfig"]                      = "bbe6b383a1e85d3a84b54a43f7d9d83567c150cb",
    ["mason-org/mason.nvim"]                       = "2a6940af80375532e5e9e7c1f2fc6319a1b7a69d", -- v2.3.1
    ["mason-org/mason-lspconfig.nvim"]             = "40276c4df7e6bdce6801d6c035c6227f9115a855",
    ["WhoIsSethDaniel/mason-tool-installer.nvim"]  = "443f1ef8b5e6bf47045cb2217b6f748a223cf7dc",
    ["j-hui/fidget.nvim"]                          = "6f793b2bcd2d35e201c09520f698bb763220908a",
    ["seblyng/roslyn.nvim"]                        = "de9a98d61ed3fd01b5016eea5fe9e32f1a4c7cfb",
    -- Bumped from 40aedd8 to pick up the fix for shell injection via file names in the previewer.
    ["nvim-telescope/telescope.nvim"]              = "1e1bab730218eaf97fce743be3f56e51075928ac",
    ["nvim-telescope/telescope-fzf-native.nvim"]   = "b25b749b9db64d375d782094e2b9dce53ad53a40",
    ["nvim-telescope/telescope-project.nvim"]      = "8e11df94419e444601c09828dadf70890484e443",
    -- blink.cmp downloads its native fuzzy matcher for the git tag at this commit, so keep
    -- this on a tagged release commit (or set fuzzy.prebuilt_binaries.force_version).
    ["saghen/blink.cmp"]                           = "78336bc89ee5365633bcf754d93df01678b5c08f", -- v1.10.2
    ["L3MON4D3/LuaSnip"]                           = "642b0c595e11608b4c18219e93b88d7637af27bc", -- v2.5.0
    ["rafamadriz/friendly-snippets"]               = "6cd7280adead7f586db6fccbd15d2cac7e2188b9",
    ["ray-x/lsp_signature.nvim"]                   = "b7ace9ddb1640ce266012a45a672dfdaedfa5ec6",
    ["nvim-treesitter/nvim-treesitter"]            = "427e9222363d07c32d6db6169e4049c28d58d141", -- also pins parser revisions
    ["windwp/nvim-autopairs"]                      = "430522f95fe4fb7c511ec64f8c1a90cc6a66c05c",
    ["numToStr/Comment.nvim"]                      = "e30b7f2008e52442154b66f7c519bfd2f1e32acb",
    ["JoosepAlviste/nvim-ts-context-commentstring"] = "6141a40173c6efa98242dc951ed4b6f892c97027",
    ["gnikdroy/projections.nvim"]                  = "889914169fa1f5c00fb8659653b5a8330fb223e6",
    ["A7Lavinraj/fyler.nvim"]                      = "70e1202434a21b45649dd59ec82dc3330f79125e",
    ["nvim-mini/mini.icons"]                       = "98faae31e9be1cc054ae63485e58ceb185efcad0",
    ["nvim-mini/mini.bufremove"]                   = "281bb1a2c60c3618c854bef2c0933276eb2362c2",
    ["folke/which-key.nvim"]                       = "3aab2147e74890957785941f0c1ad87d0a44c15a",
    ["hat0uma/csvview.nvim"]                       = "2466bdda54047f525d4faca53040fe657c9c33db",
    ["folke/snacks.nvim"]                          = "882c996cf28183f4d63640de0b4c02ec886d01f2",
    ["MeanderingProgrammer/render-markdown.nvim"]  = "4663eb3ecd538bd5062628fb6d95bbe6bdca78f6",
}

-- Mason resolves package versions from its registry. Pinning the registry release means
-- `:MasonUpdate` and Mason's "update all" can't move anything past this snapshot.
M.mason_registry = "github:mason-org/mason-registry@2026-11-23-caring-song"

---@type table<string, string> lspconfig server name -> Mason package version
M.mason_servers = {
    lua_ls = "3.19.2",       -- lua-language-server (GitHub release LuaLS/lua-language-server)
    basedpyright = "1.40.2", -- basedpyright (PyPI)
    clangd = "23.1.0",       -- clangd (GitHub release clangd/clangd)
}

-- Installed outside Mason as a .NET global tool (see mosukiton.lsp.lspconfig.roslyn).
M.roslyn_language_server = "5.13.0-1.26514.10"

---Returns `name@version` for Mason's `ensure_installed`, failing loudly for unpinned servers.
---@param server_name string
---@return string
function M.mason_server(server_name)
    local version = M.mason_servers[server_name]
    if not version then
        error(("LSP server %q has no pinned version in lua/mosukiton/pins.lua"):format(server_name))
    end
    return server_name .. "@" .. version
end

---@param server_names string[]
---@return string[]
function M.mason_ensure_installed(server_names)
    local list = vim.tbl_map(M.mason_server, server_names)
    table.sort(list)
    return list
end

return M
