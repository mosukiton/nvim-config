local servers = {
    -- "omnisharp",
    "lua_ls",
	"pyright",
	"jsonls",
}

local settings = {
	ui = {
		border = "none",
		icons = {
			package_installed = "◍",
			package_pending = "◍",
			package_uninstalled = "◍",
		},
	},
	log_level = vim.log.levels.INFO,
	max_concurrent_installers = 4,
    registries = {
        "github:mason-org/mason-registry",
        "github:Crashdummyy/mason-registry",
    },
}

require("mason").setup(settings)
require("mason-lspconfig").setup({
	ensure_installed = servers,
	automatic_installation = true,
})

local lspconfig_status_ok, lspconfig = pcall(require, "lspconfig")
if not lspconfig_status_ok then
    return
end

local opts = {}

for _, server in pairs(servers) do
	opts = {
		on_attach = require("local.lsp.handlers").on_attach,
		capabilities = require("local.lsp.handlers").capabilities,
	}

	server = vim.split(server, "@")[1]

	local require_ok, conf_opts = pcall(require, "local.lsp.settings." .. server)
	if require_ok then
		opts = vim.tbl_deep_extend("force", conf_opts, opts)
	end

	lspconfig[server].setup(opts)
end

-- lspconfig["omnisharp"].setup({
--     cmd = { "omnisharp", '--languageserver', '--hostPID', tostring(vim.fn.getpid()) },
--     handlers = {
--         ["textDocument/definition"] = require('omnisharp_extended').handler,
--     },
-- 	-- on_attach = require("local.lsp.handlers").on_attach,
-- 	on_attach = function (client, bufnr)
-- 	     --- Guard against servers without the signatureHelper capability
--         -- if client.server_capabilities.signatureHelpProvider then
--         --     require('lsp-overloads').setup(client, {
--         --         keymaps = {
--         --             next_signature = "<C-j>",
--         --             previous_signature = "<C-k>",
--         --             next_parameter = "<C-l>",
--         --             previous_parameter = "<C-h>",
--         --             close_signature = "<A-s>"
--         --         },
--         --         display_automatically = true -- Uses trigger characters to automatically display the signature overloads when typing a method signature
--         --     })
--         -- end
--         require("local.lsp.handlers").on_attach(client, bufnr)
--     end,
-- 	capabilities = require("local.lsp.handlers").capabilities,
--     -- on_init = require("local.lsp.handlers").common_on_init,
--     filetypes = { "cs", "csproj", "sln" },
--     root_dir = require('lspconfig.util').root_pattern('*.sln'),
--     enable_editorconfig_support = true,
--     enable_roslyn_analyzers = true,
--     organize_imports_on_format = true,
--     enable_import_completion = false,
-- })
