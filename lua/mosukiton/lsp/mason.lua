return {
    ui = {
        border = "rounded",
        icons = {
            package_installed = "◍",
            package_pending = "◍",
            package_uninstalled = "◍",
        },
    },
    log_level = vim.log.levels.INFO,
    max_concurrent_installers = 4,
    -- Pinned registry snapshot; see lua/mosukiton/pins.lua.
    registries = { require("mosukiton.pins").mason_registry },
    -- Roslyn is installed as the cross-platform .NET global tool
    -- `roslyn-language-server`, so Mason does not need a custom registry.
}
