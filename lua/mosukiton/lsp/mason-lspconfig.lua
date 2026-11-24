return {
    -- These servers are managed by Mason; Roslyn is installed separately
    -- as the `roslyn-language-server` .NET global tool.
    -- `name@version` entries; versions are pinned in lua/mosukiton/pins.lua.
    ensure_installed = require("mosukiton.pins").mason_ensure_installed(
        vim.tbl_keys(require("mosukiton.lsp.servers") or {})
    ),
}
