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
    -- Roslyn is installed as the cross-platform .NET global tool
    -- `roslyn-language-server`, so Mason does not need a custom registry.
}
