return {
    auto_confirm_simple_mutation = false,
    use_as_default_explorer = false,
    follow_current_file = true,
    kind = "floating",

    extensions = {
        git = {
            enabled = true,
            icons = {
                [" M"] = { icon = "*", hl = "FylerGitModified" },
                ["M "] = { icon = "+", hl = "FylerGitStaged" },
                ["MM"] = { icon = "+", hl = "FylerGitStaged" },
                ["??"] = { icon = "?", hl = "FylerGitUntracked" },
                [" D"] = { icon = "x", hl = "FylerGitDeleted" },
                ["D "] = { icon = "x", hl = "FylerGitStaged" },
                ["R "] = { icon = ">", hl = "FylerGitRenamed" },
                ["UU"] = { icon = "!", hl = "FylerGitConflict" },
                ["!!"] = { icon = "#", hl = "FylerGitIgnored" },
            },
        },
    },

    integrations = {
        icon = "mini_icons",
    },

    ui = {
        indent_guides = true,
    },

    kind_presets = {
        floating = {
            border = "single",
            mappings = {
                n = {
                    ["<CR>"] = {
                        action = "select",
                        args = { close = true, pick = false },
                    },
                },
            },
        },
    },

    mappings = {
        n = {
            q = { action = "close" },
            ["<CR>"] = { action = "select", args = { close = true, pick = true } },
            ["<C-t>"] = { action = "select", args = { tabedit = true } },
            ["|"] = { action = "select", args = { vsplit = true } },
            ["-"] = { action = "select", args = { split = true } },
            ["^"] = { action = "visit", args = { parent = true } },
            ["="] = { action = "visit" },
            ["."] = { action = "visit", args = { cursor = true } },
            ["#"] = { action = "shrink" },
            ["<BS>"] = { action = "shrink", args = { parent = true } },
        },
    },
}
