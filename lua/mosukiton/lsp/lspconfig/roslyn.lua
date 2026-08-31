---@return string[] command and arguments used to start Roslyn
local function get_roslyn_cmd()
    -- `roslyn-language-server` is exposed by the .NET global tool on both
    -- Linux and Windows, so no platform-specific executable path is needed.
    return {
        "roslyn-language-server",
        "--logLevel=Information",
        "--extensionLogDirectory=" .. vim.fs.dirname(vim.lsp.log.get_filename()),
        "--telemetryLevel=off",
        "--stdio",
    }
end

---@type vim.lsp.Config
local config = {
    -- Install once per machine with:
    -- `dotnet tool install --global roslyn-language-server --prerelease`
    -- The .NET global-tools directory must be on PATH.
    cmd = get_roslyn_cmd(),

    -- roslyn.nvim supplies solution selection and source-generated-file support.
    filetypes = { "cs" },

    -- `settings` is sent to Roslyn during LSP initialization. Plugin-only
    -- options such as file watching and target locking live in plugins.lua.
    settings = {
        ["csharp|inlay_hints"] = {
            csharp_enable_inlay_hints_for_implicit_object_creation = true,
            csharp_enable_inlay_hints_for_implicit_variable_types = true,
        },
        ["csharp|code_lens"] = {
            dotnet_enable_references_code_lens = true,
        },
    },
}

return config
