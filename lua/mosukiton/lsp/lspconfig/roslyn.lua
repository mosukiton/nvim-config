-- cmd function stolen from roslyn.nvim
local sysname = vim.uv.os_uname().sysname:lower()
local iswin = not not (sysname:find("windows") or sysname:find("mingw"))

local function get_default_cmd()
    local roslyn_bin = iswin and "roslyn.cmd" or "roslyn"
    local mason_bin = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "bin", roslyn_bin)

    local exe = vim.fn.executable(mason_bin) == 1 and mason_bin
        or vim.fn.executable(roslyn_bin) == 1 and roslyn_bin
        or "Microsoft.CodeAnalysis.LanguageServer"

    return {
        exe,
        "--logLevel=Information",
        "--extensionLogDirectory=" .. vim.fs.dirname(vim.lsp.log.get_filename()),
        "--telemetryLevel=off", -- added telemetry off to futureproof in case it gets turned on by default later
        "--stdio"
    }
end

local config = {
    --  - cmd (table): Override the default command used to start the server
    cmd = get_default_cmd(),

    --  - filetypes (table): Override the default list of associated filetypes for the server
    filetypes = { "cs" },

    --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
    -- capabilities = {},

    --  - settings (table): Override the default settings passed when initializing the server.
    setting = {
        -- "auto" | "roslyn" | "off"
        --
        -- - "auto": Does nothing for filewatching, leaving everything as default
        -- - "roslyn": Turns off neovim filewatching which will make roslyn do the filewatching
        -- - "off": Hack to turn off all filewatching. (Can be used if you notice performance issues)
        filewatching = "roslyn",

        -- Optional function that takes an array of targets as the only argument. Return the target you
        -- want to use. If it returns `nil`, then it falls back to guessing the target like normal
        -- Example:
        --
        -- choose_target = function(target)
        --     return vim.iter(target):find(function(item)
        --         if string.match(item, "Foo.sln") then
        --             return item
        --         end
        --     end)
        -- end
        choose_target = nil,

        -- Optional function that takes the selected target as the only argument.
        -- Returns a boolean of whether it should be ignored to attach to or not
        --
        -- I am for example using this to disable a solution with a lot of .NET Framework code on mac
        -- Example:
        --
        -- ignore_target = function(target)
        --     return string.match(target, "Foo.sln") ~= nil
        -- end
        ignore_target = nil,

        -- Whether or not to look for solution files in the child of the (root).
        -- Set this to true if you have some projects that are not a child of the
        -- directory with the solution file
        broad_search = false,

        -- Whether or not to lock the solution target after the first attach.
        -- This will always attach to the target in `vim.g.roslyn_nvim_selected_solution`.
        -- NOTE: You can use `:Roslyn target` to change the target
        lock_target = true,

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
