local debug = require("mosukiton.lsp.roslyn_debug")

local M = {}

local setup_group = vim.api.nvim_create_augroup("mosukiton-roslyn-solution-diagnostics", { clear = true })

local FETCH_TIMEOUT_MS = 60 * 1000
local ANALYSIS_WAIT_MS = 4 * 1000
local REGISTRATION_WAIT_MS = 60 * 1000
local REGISTRATION_POLL_MS = 250
local MAX_CONCURRENT = 8

---@return vim.lsp.Client?
local function get_roslyn_client()
    return vim.lsp.get_clients({ name = "roslyn", bufnr = 0 })[1]
end

---@param client vim.lsp.Client
---@param callback fun(ready: boolean)
local function wait_for_pull_support(client, callback)
    local deadline = vim.uv.now() + REGISTRATION_WAIT_MS

    local function poll()
        if client:supports_method("textDocument/diagnostic") then
            callback(true)
            return
        end

        if vim.uv.now() >= deadline then
            callback(false)
            return
        end

        vim.defer_fn(poll, REGISTRATION_POLL_MS)
    end

    poll()
end

---@param filepath string
---@return boolean
local function is_source_cs_file(filepath)
    return not filepath:match("/obj/") and not filepath:match("\\obj\\")
        and not filepath:match("/bin/") and not filepath:match("\\bin\\")
end

---@param root_dir string
---@return string[]
local function discover_cs_files(root_dir)
    if not root_dir or root_dir == "" then
        return {}
    end

    local pattern = vim.fs.joinpath(root_dir, "**/*.cs")
    local files = vim.fn.glob(pattern, false, true)
    if type(files) == "string" then
        files = files == "" and {} or { files }
    end

    local filtered = vim.tbl_filter(is_source_cs_file, files)
    table.sort(filtered)
    return filtered
end

--- Roslyn only returns textDocument/diagnostic results for loaded, LSP-attached buffers.
---@param client vim.lsp.Client
---@param filepath string
---@return integer bufnr
---@return boolean newly_attached
local function ensure_file_attached(client, filepath)
    local bufnr = vim.fn.bufadd(filepath)
    vim.api.nvim_set_option_value("bufhidden", "hide", { buf = bufnr })
    vim.api.nvim_set_option_value("buflisted", false, { buf = bufnr })

    if not vim.api.nvim_buf_is_loaded(bufnr) then
        vim.fn.bufload(bufnr)
    end

    local newly_attached = false
    if not vim.lsp.buf_is_attached(bufnr, client.id) then
        vim.lsp.buf_attach_client(bufnr, client.id)
        newly_attached = true
    end

    return bufnr, newly_attached
end

---@param client vim.lsp.Client
---@param cs_files string[]
---@return integer newly_attached
local function prepare_solution_buffers(client, cs_files)
    local newly_attached = 0

    for _, filepath in ipairs(cs_files) do
        local _, attached = ensure_file_attached(client, filepath)
        if attached then
            newly_attached = newly_attached + 1
        end
    end

    return newly_attached
end

---@param filepath string
---@param diag lsp.Diagnostic
---@param seen table<string, boolean>
---@return table?
local function lsp_diag_to_qf_entry(filepath, diag, seen)
    local key = table.concat({
        filepath,
        tostring(diag.range.start.line),
        tostring(diag.range.start.character),
        diag.message or "",
    }, "|")

    if seen[key] then
        return nil
    end

    seen[key] = true
    return {
        filename = filepath,
        lnum = diag.range.start.line + 1,
        col = diag.range.start.character + 1,
        text = diag.message,
        type = diag.severity == 1 and "E" or diag.severity == 2 and "W" or "I",
    }
end

---@param filepath string
---@param items lsp.Diagnostic[]
---@param seen table<string, boolean>
---@return table[]
local function merge_lsp_diagnostics(filepath, items, seen)
    local entries = {}
    for _, diag in ipairs(items or {}) do
        local entry = lsp_diag_to_qf_entry(filepath, diag, seen)
        if entry then
            entries[#entries + 1] = entry
        end
    end
    return entries
end

local active_fetch = false
local timeout_timer = nil ---@type integer?
local analysis_timer = nil ---@type integer?
local in_flight = 0
local file_queue = {} ---@type string[]
local pending_request_ids = {} ---@type integer[]
local qf_entries = {} ---@type table[]
local seen_entries = {} ---@type table<string, boolean>
local fetch_client = nil ---@type vim.lsp.Client?
local pull_diagnostics = 0

local function clear_fetch_state()
    active_fetch = false
    in_flight = 0
    file_queue = {}
    pending_request_ids = {}
    qf_entries = {}
    seen_entries = {}
    fetch_client = nil
    pull_diagnostics = 0

    if timeout_timer then
        vim.fn.timer_stop(timeout_timer)
        timeout_timer = nil
    end
    if analysis_timer then
        vim.fn.timer_stop(analysis_timer)
        analysis_timer = nil
    end
end

---@param reason string
local function finish_fetch(reason)
    if not active_fetch then
        return
    end

    debug.log("info", "finish_fetch", {
        reason = reason,
        qf_count = #qf_entries,
        pull_diagnostics = pull_diagnostics,
    })

    if fetch_client then
        for _, req_id in ipairs(pending_request_ids) do
            pcall(fetch_client.cancel_request, fetch_client, req_id)
        end
    end

    local entries = qf_entries
    local count = #entries
    clear_fetch_state()

    vim.fn.setqflist({}, "r", { items = entries })

    if count > 0 then
        vim.cmd("copen")
    end

    vim.notify(
        string.format("Solution diagnostics ready (%d entries)", count),
        vim.log.levels.INFO,
        { title = "Roslyn" }
    )
end

---@param client vim.lsp.Client
---@param filepath string
---@param on_done fun()
local function pull_file_diagnostics(client, filepath, on_done)
    in_flight = in_flight + 1

    local params = {
        textDocument = { uri = vim.uri_from_fname(filepath) },
    }

    local ok, req_id = client:request("textDocument/diagnostic", params, function(err, result)
        in_flight = in_flight - 1

        if err == nil and result and result.items then
            pull_diagnostics = pull_diagnostics + #result.items
            vim.list_extend(qf_entries, merge_lsp_diagnostics(filepath, result.items, seen_entries))
        end

        on_done()
    end)

    if ok and req_id then
        pending_request_ids[#pending_request_ids + 1] = req_id
    else
        in_flight = in_flight - 1
        on_done()
    end
end

---@param client vim.lsp.Client
local function pump_pull_queue(client)
    while in_flight < MAX_CONCURRENT and #file_queue > 0 do
        local filepath = table.remove(file_queue, 1)
        pull_file_diagnostics(client, filepath, function()
            if not active_fetch then
                return
            end

            if #file_queue == 0 and in_flight == 0 then
                finish_fetch("all document pulls responded")
            else
                pump_pull_queue(client)
            end
        end)
    end
end

---@param client vim.lsp.Client
---@param cs_files string[]
local function start_fetch_after_prepare(client, cs_files)
    local newly_attached = prepare_solution_buffers(client, cs_files)

    local wait_ms = newly_attached > 0 and ANALYSIS_WAIT_MS or 0
    if wait_ms > 0 then
        vim.notify(
            string.format("Analyzing %d solution files…", #cs_files),
            vim.log.levels.INFO,
            { title = "Roslyn" }
        )
    end

    analysis_timer = vim.fn.timer_start(wait_ms, function()
        analysis_timer = nil
        if active_fetch then
            pump_pull_queue(client)
        end
    end)
end

---@class mosukiton.roslyn_solution_diagnostics.Opts
---@field client_id? integer

---Fetch solution-wide diagnostics asynchronously and populate the quickfix list.
---@param opts? mosukiton.roslyn_solution_diagnostics.Opts
function M.fetch_to_qflist(opts)
    opts = opts or {}

    if active_fetch then
        vim.notify("Solution diagnostics fetch already in progress", vim.log.levels.WARN, { title = "Roslyn" })
        return
    end

    local client = opts.client_id and vim.lsp.get_client_by_id(opts.client_id) or get_roslyn_client()
    if not client then
        vim.notify("Roslyn LSP client is not running", vim.log.levels.ERROR, { title = "Roslyn" })
        return
    end

    debug.log_client_state(client, "before fetch")

    if not client:supports_method("textDocument/diagnostic") then
        vim.notify("Waiting for Roslyn project analysis…", vim.log.levels.INFO, { title = "Roslyn" })
    end

    wait_for_pull_support(client, function(ready)
        if not ready then
            local message = "Roslyn diagnostic providers not ready yet (see :RoslynDebug status)"
            debug.log("error", message, debug.dump_client_state(client))
            vim.notify(message, vim.log.levels.ERROR, { title = "Roslyn" })
            return
        end

        if active_fetch then
            return
        end

        local cs_files = discover_cs_files(client.config.root_dir)
        if #cs_files == 0 then
            vim.notify("No C# files found under Roslyn root_dir", vim.log.levels.ERROR, { title = "Roslyn" })
            return
        end

        active_fetch = true
        fetch_client = client
        qf_entries = {}
        seen_entries = {}
        file_queue = vim.deepcopy(cs_files)
        pending_request_ids = {}
        in_flight = 0
        pull_diagnostics = 0

        local notify_message = debug.enabled()
            and string.format("Fetching solution diagnostics… (%d files, :LspLog)", #cs_files)
            or string.format("Fetching solution diagnostics… (%d files)", #cs_files)

        vim.notify(notify_message, vim.log.levels.INFO, { title = "Roslyn" })

        timeout_timer = vim.fn.timer_start(FETCH_TIMEOUT_MS, function()
            if active_fetch then
                finish_fetch("timeout")
            end
        end)

        start_fetch_after_prepare(client, cs_files)
    end)
end

function M.setup()
    vim.api.nvim_create_user_command("RoslynSolutionDiagnostics", function()
        M.fetch_to_qflist()
    end, { desc = "Fetch C# solution diagnostics into the quickfix list" })

    vim.api.nvim_create_autocmd("LspAttach", {
        group = setup_group,
        callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if not client or client.name ~= "roslyn" then
                return
            end

            vim.keymap.set("n", "<leader>lq", function()
                M.fetch_to_qflist({ client_id = client.id })
            end, {
                buffer = args.buf,
                desc = "LSP: Solution [Q]uickfix diagnostics",
            })
        end,
    })
end

return M
