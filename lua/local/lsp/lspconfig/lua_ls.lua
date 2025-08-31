return {

    --  - cmd (table): Override the default command used to start the server
    -- cmd = { },
    --  - filetypes (table): Override the default list of associated filetypes for the server
    -- filetypes = {},
    --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
    -- capabilities = {},
    --  - settings (table): Override the default settings passed when initializing the server.
	settings = {

		Lua = {
            -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
            -- diagnostics = { disable = { 'missing-fields' } },
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				library = {
					[vim.fn.expand("$VIMRUNTIME/lua")] = true,
                    -- "${3rd}/luv/library",
                    -- "${3rd}/busted/library",
				},
			},
            completion = {
                callSnippet = 'Replace',
            },
		},
	},
}
