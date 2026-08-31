return {
    -- These servers are managed by Mason; Roslyn is installed separately
    -- as the `roslyn-language-server` .NET global tool.
    ensure_installed = vim.tbl_keys(require("mosukiton.lsp.servers") or {}),
}
