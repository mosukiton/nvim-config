local M = {}

local LOG_PREFIX = "roslyn-debug"

---@return boolean
function M.enabled()
    if vim.g.roslyn_debug == true then
        return true
    end

    local env = vim.env.ROSLYN_DEBUG
    return env == "1" or env == "true"
end

---@param level? string
---@param ... any
function M.log(level, ...)
    if not M.enabled() then
        return
    end

    level = level or "debug"
    local logger = vim.lsp.log[level]
    if logger then
        logger(LOG_PREFIX, ...)
    end
end

function M.configure_lsp_logging()
    if not M.enabled() then
        return
    end

    vim.lsp.log.set_level("trace")
    M.log("info", "LSP client log level set to trace", vim.lsp.log.get_filename())
end

---@return string
function M.roslyn_log_level()
    return M.enabled() and "Trace" or "Information"
end

---@param client vim.lsp.Client
---@return table
function M.dump_client_state(client)
    local registrations = {}
    for provider, regs in pairs(client.registrations or {}) do
        registrations[provider] = vim.tbl_map(function(reg)
            return {
                id = reg.id,
                method = reg.method,
                registerOptions = reg.registerOptions,
            }
        end, regs)
    end

    return {
        id = client.id,
        name = client.name,
        root_dir = client.config.root_dir,
        supports_workspace_diagnostic = client:supports_method(vim.lsp.protocol.Methods.workspace_diagnostic),
        diagnostic_provider = client.server_capabilities.diagnosticProvider,
        registrations = registrations,
        pending_requests = client.requests and vim.tbl_count(client.requests) or 0,
        lsp_log = vim.lsp.log.get_filename(),
    }
end

---@param client vim.lsp.Client
function M.log_client_state(client, context)
    M.log("info", context, M.dump_client_state(client))
end

function M.open_lsp_log()
    local logfile = vim.lsp.log.get_filename()
    vim.cmd("tabnew " .. vim.fn.fnameescape(logfile))
end

function M.setup_commands()
    vim.api.nvim_create_user_command("RoslynDebug", function(opts)
        local action = opts.fargs[1] or "status"

        if action == "on" then
            vim.g.roslyn_debug = true
            vim.lsp.log.set_level("trace")
            vim.notify(
                "Roslyn debug enabled for this session. Restart Neovim for Roslyn server Trace logs.",
                vim.log.levels.INFO,
                { title = "Roslyn Debug" }
            )
            return
        end

        if action == "off" then
            vim.g.roslyn_debug = false
            vim.lsp.log.set_level("warn")
            vim.notify("Roslyn debug disabled for this session", vim.log.levels.INFO, { title = "Roslyn Debug" })
            return
        end

        if action == "logs" or action == "log" then
            M.open_lsp_log()
            return
        end

        if action == "status" then
            local client = vim.lsp.get_clients({ name = "roslyn", bufnr = 0 })[1]
            if not client then
                vim.notify("Roslyn client is not running", vim.log.levels.WARN, { title = "Roslyn Debug" })
                return
            end

            local state = M.dump_client_state(client)
            vim.notify(vim.inspect(state), vim.log.levels.INFO, { title = "Roslyn Debug" })
            M.log_client_state(client, "manual status dump")
            return
        end

        vim.notify(
            "Usage: :RoslynDebug [on|off|status|logs]",
            vim.log.levels.WARN,
            { title = "Roslyn Debug" }
        )
    end, {
        nargs = "?",
        complete = function()
            return { "on", "off", "status", "logs" }
        end,
        desc = "Roslyn/LSP debugging helpers",
    })

    vim.api.nvim_create_user_command("LspLog", function()
        M.open_lsp_log()
    end, { desc = "Open the Neovim LSP log file" })
end

return M
