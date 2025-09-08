return {
    ensure_installed = vim.tbl_keys(require("mosukiton.lsp.servers") or {}),
    automatic_installation = true,
}
