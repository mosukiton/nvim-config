local debug = require("mosukiton.lsp.roslyn_debug")

---@param client vim.lsp.Client
local function patch_workspace_diagnostics_capability(client)
    client.server_capabilities.diagnosticProvider = vim.tbl_deep_extend(
        "force",
        client.server_capabilities.diagnosticProvider or {},
        { workspaceDiagnostics = true }
    )

    for _, reg in ipairs(client.registrations.diagnosticProvider or {}) do
        if reg.registerOptions then
            reg.registerOptions.workspaceDiagnostics = true
        end
    end
end

---@return string[] command and arguments used to start Roslyn
local function get_roslyn_cmd()
    -- `roslyn-language-server` is exposed by the .NET global tool on both
    -- Linux and Windows, so no platform-specific executable path is needed.
    return {
        "roslyn-language-server",
        "--logLevel=" .. debug.roslyn_log_level(),
        "--extensionLogDirectory=" .. vim.fs.dirname(vim.lsp.log.get_filename()),
        "--telemetryLevel=off", -- added telemetry off to futureproof in case it gets turned on by default later
        "--stdio",
    }
end

---@type vim.lsp.Config
local config = {
    -- Install once per machine with:
    -- `dotnet tool install --global roslyn-language-server --prerelease`
    -- The .NET global-tools directory must be on PATH.
    cmd = get_roslyn_cmd(),

    -- Overrides for the `roslyn` server registered by roslyn.nvim (not `roslyn_ls`).
    filetypes = { "cs" },

    -- Sent to Roslyn during LSP initialization. Plugin-only options live in plugins.lua.
    settings = {
        ["csharp|background_analysis"] = {
            ["background_analysis.dotnet_compiler_diagnostics_scope"] = "fullSolution",
            ["background_analysis.dotnet_analyzer_diagnostics_scope"] = "fullSolution",
        },
        ["csharp|inlay_hints"] = {
            csharp_enable_inlay_hints_for_implicit_object_creation = true,
            csharp_enable_inlay_hints_for_implicit_variable_types = true,
        },
        ["csharp|code_lens"] = {
            dotnet_enable_references_code_lens = true,
        },
    },

    on_attach = function(client)
        patch_workspace_diagnostics_capability(client)
        debug.log_client_state(client, "on_attach")
    end,
}

config.patch_workspace_diagnostics_capability = patch_workspace_diagnostics_capability

return config
