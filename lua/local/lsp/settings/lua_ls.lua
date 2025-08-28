return {
	settings = {

		Lua = {
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
		},
	},
}
