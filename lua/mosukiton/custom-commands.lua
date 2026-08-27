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

--JsonMinifyDepth
local function is_json_container_start(char)
  return char == "{" or char == "["
end


-- Find the first complete JSON object/array inside a range of lines.
--
-- Returns:
--   start_line, start_col, end_line, end_col
--
-- All positions are 0-based and end_col is exclusive.
local function find_first_json_container(lines)
  local in_string = false
  local escaped = false
  local stack = {}

  local start_line = nil
  local start_col = nil

  for line_idx, line in ipairs(lines) do
    local i = 1

    while i <= #line do
      local char = line:sub(i, i)

      if in_string then
        if escaped then
          escaped = false
        elseif char == "\\" then
          escaped = true
        elseif char == '"' then
          in_string = false
        end

        i = i + 1
        goto continue
      end

      if char == '"' then
        in_string = true
        i = i + 1
        goto continue
      end

      if char == "{" or char == "[" then
        -- Only start looking for a candidate when we're not
        -- already inside another container.
        if #stack == 0 then
          start_line = line_idx
          start_col = i - 1
        end

        table.insert(stack, char)

      elseif char == "}" or char == "]" then
        if #stack > 0 then
          local expected = stack[#stack] == "{" and "}" or "]"

          if char ~= expected then
            -- Invalid/mismatched container. Reset and keep scanning.
            stack = {}
            start_line = nil
            start_col = nil
          else
            table.remove(stack)

            if #stack == 0 and start_line ~= nil then
              return start_line, start_col, line_idx, i
            end
          end
        end
      end

      i = i + 1

      ::continue::
    end
  end

  return nil
end


local function format_json(data, depth)
  local function is_array(t)
    if type(t) ~= "table" then
      return false
    end

    local max = 0

    for k, _ in pairs(t) do
      if type(k) ~= "number" then
        return false
      end

      max = math.max(max, k)
    end

    for i = 1, max do
      if t[i] == nil then
        return false
      end
    end

    return true
  end

  local function encode(value, current_depth)
    -- Scalars are always normal JSON.
    if type(value) ~= "table" then
      return vim.json.encode(value)
    end

    -- At or below the requested depth, emit compact JSON.
    if current_depth >= depth then
      return vim.json.encode(value)
    end

    local parts = {}
    local indent = string.rep("  ", current_depth)
    local child_indent = string.rep("  ", current_depth + 1)

    if is_array(value) then
      for i = 1, #value do
        table.insert(
          parts,
          encode(value[i], current_depth + 1)
        )
      end

      if #parts == 0 then
        return "[]"
      end

      return "[\n"
        .. child_indent
        .. table.concat(parts, ",\n" .. child_indent)
        .. "\n"
        .. indent
        .. "]"
    end

    local keys = {}

    for key, _ in pairs(value) do
      table.insert(keys, key)
    end

    table.sort(keys)

    for _, key in ipairs(keys) do
      table.insert(
        parts,
        vim.json.encode(key)
          .. ": "
          .. encode(value[key], current_depth + 1)
      )
    end

    if #parts == 0 then
      return "{}"
    end

    return "{\n"
      .. child_indent
      .. table.concat(parts, ",\n" .. child_indent)
      .. "\n"
      .. indent
      .. "}"
  end

  return encode(data, 0)
end


local function replace_json_container(
  start_line,
  start_col,
  end_line,
  end_col,
  depth
)
  local buf = vim.api.nvim_get_current_buf()

  local lines = vim.api.nvim_buf_get_lines(
    buf,
    start_line,
    end_line + 1,
    false
  )

  -- Include the final line and trim it to the exact JSON range.
  lines[#lines] = lines[#lines]:sub(1, end_col)

  -- Trim the beginning of the first line.
  lines[1] = lines[1]:sub(start_col + 1)

  local input = table.concat(lines, "\n")

  local ok, data = pcall(vim.json.decode, input)

  if not ok then
    vim.notify(
      "JsonMinifyDepth: found container is not valid JSON",
      vim.log.levels.ERROR
    )
    return false
  end

  local output = format_json(data, depth)

  local replacement = vim.split(
    output,
    "\n",
    { plain = true }
  )

  -- Get the original first/final lines so we can preserve
  -- everything outside the JSON container.
  local original_start = vim.api.nvim_buf_get_lines(
    buf,
    start_line,
    start_line + 1,
    false
  )[1]

  local original_end = vim.api.nvim_buf_get_lines(
    buf,
    end_line,
    end_line + 1,
    false
  )[1]

  local prefix = original_start:sub(1, start_col)
  local suffix = original_end:sub(end_col + 1)

  replacement[1] = prefix .. replacement[1]
  replacement[#replacement] = replacement[#replacement] .. suffix

  vim.api.nvim_buf_set_lines(
    buf,
    start_line,
    end_line + 1,
    false,
    replacement
  )

  return true
end


local function json_minify_depth(depth, start_line, end_line, explicit_range)
  local buf = vim.api.nvim_get_current_buf()

  -- Whole-buffer behavior remains unchanged.
  if not explicit_range then
    local lines = vim.api.nvim_buf_get_lines(
      buf,
      0,
      -1,
      false
    )

    local input = table.concat(lines, "\n")

    local ok, data = pcall(vim.json.decode, input)

    if not ok then
      vim.notify(
        "JsonMinifyDepth: invalid JSON",
        vim.log.levels.ERROR
      )
      return
    end

    local output = format_json(data, depth)

    vim.api.nvim_buf_set_lines(
      buf,
      0,
      -1,
      false,
      vim.split(output, "\n", { plain = true })
    )

    return
  end

  -- For an explicit range, first try the entire selection.
  local selected = vim.api.nvim_buf_get_lines(
    buf,
    start_line,
    end_line,
    false
  )

  local input = table.concat(selected, "\n")

  local ok, data = pcall(vim.json.decode, input)

  if ok then
    local output = format_json(data, depth)

    vim.api.nvim_buf_set_lines(
      buf,
      start_line,
      end_line,
      false,
      vim.split(output, "\n", { plain = true })
    )

    return
  end

  -- The selection isn't itself valid JSON.
  -- Find the first complete JSON container inside it.
  local found_start_line,
    found_start_col,
    found_end_line,
    found_end_col =
      find_first_json_container(selected)

  if not found_start_line then
    vim.notify(
      "JsonMinifyDepth: no valid JSON object/array found in selection",
      vim.log.levels.ERROR
    )
    return
  end

  -- Convert relative selection positions into buffer positions.
  local absolute_start_line =
    start_line + found_start_line

  local absolute_end_line =
    start_line + found_end_line

  replace_json_container(
    absolute_start_line,
    found_start_col,
    absolute_end_line,
    found_end_col,
    depth
  )
end


vim.api.nvim_create_user_command("JsonMinifyDepth", function(opts)
  local depth = tonumber(opts.args)

  if not depth or depth < 0 then
    vim.notify(
      "Usage: :JsonMinifyDepth <depth>",
      vim.log.levels.ERROR
    )
    return
  end

  if opts.range == 0 then
    json_minify_depth(
      depth,
      0,
      vim.api.nvim_buf_line_count(0),
      false
    )
  else
    json_minify_depth(
      depth,
      opts.line1 - 1,
      opts.line2,
      true
    )
  end
end, {
  nargs = 1,
  range = true,
})
