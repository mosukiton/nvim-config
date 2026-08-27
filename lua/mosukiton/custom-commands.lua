vim.api.nvim_create_user_command("LspCapabilities", function()
	local curBuf = vim.api.nvim_get_current_buf()
	-- local clients = vim.lsp.get_active_clients { bufnr = curBuf }
	local clients = vim.lsp.get_clients { bufnr = curBuf }

	for _, client in pairs(clients) do
		if client.name ~= "null-ls" then
			local capAsList = {}
			for key, value in pairs(client.server_capabilities) do
				if value and key:find("Provider") then
					local capability = key:gsub("Provider$", "")
					table.insert(capAsList, "- " .. capability)
				end
			end
			table.sort(capAsList) -- sorts alphabetically
			local msg = "# " .. client.name .. "\n" .. table.concat(capAsList, "\n")
            local fidget = require("fidget")
			fidget.notify(msg, vim.log.levels.TRACE, {
				on_open = function(win)
					local buf = vim.api.nvim_win_get_buf(win)
					-- vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
					vim.api.nvim_buf_set_var(buf, "filetype", "markdown")
				end,
				timeout = 14000,
			})
			vim.fn.setreg("+", "Capabilities = " .. vim.inspect(client.server_capabilities))
		end
	end
end, {})

-- JsonMinifyDepth
local function json_minify_depth(depth)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local input = table.concat(lines, "\n")

  local jq_filter = string.format([[
    def compact(n):
      if n >= %d then
        tostring
      elif type == "object" then
        with_entries(.value |= compact(n + 1))
      elif type == "array" then
        map(compact(n + 1))
      else
        .
      end;

    compact(0)
  ]], depth)

  local output = vim.fn.system({
    "jq",
    "--indent", "2",
    jq_filter,
  }, input)

  if vim.v.shell_error ~= 0 then
    vim.notify("JsonMinifyDepth: invalid JSON or jq error", vim.log.levels.ERROR)
    return
  end

  vim.api.nvim_buf_set_lines(
    0,
    0,
    -1,
    false,
    vim.split(output, "\n", { trimempty = true })
  )
end

vim.api.nvim_create_user_command("JsonMinifyDepth", function(opts)
  local depth = tonumber(opts.args)

  if not depth or depth < 0 then
    vim.notify("Usage: :JsonMinifyDepth <depth>", vim.log.levels.ERROR)
    return
  end

  json_minify_depth(depth)
end, {
  nargs = 1,
})

