local opts = {
    -- put the language you want in this array
    -- ensure_installed = { "c_sharp", "lua", "markdown", "markdown_inline", "bash", "python" },

    -- ensure_installed = "all", -- one of "all" or a list of languages
    -- List of parsers to ignore installing
    ignore_install = { "" },

    -- install languages synchronously (only applied to `ensure_installed`)
    sync_install = false,

    highlight = {
        enable = true,       -- false will disable the whole extension
        disable = { }, -- list of language that will be disabled
    },

    autopairs = {
        enable = true,
    },

    indent = { enable = true, disable = { "python", "css" } },

}
return opts

-- function M.config()
--     local configs = require "nvim-treesitter.configs"
--     configs.setup(setup)
-- end
-- return configs_setup

-- return M
