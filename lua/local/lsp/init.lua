local status_ok, _ = pcall(require, "lspconfig")
if not status_ok then
    vim.notify("lspconfig is not ok!")
    return
end

require "local.lsp.mason"
require("local.lsp.handlers").setup()
require "local.lsp.null-ls"
