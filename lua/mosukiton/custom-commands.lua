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

-- Find the first valid JSON object/array inside a range of lines.
--
-- Returns:
--   start_line, start_col, end_line, end_col
--
-- All positions are 0-based and end_col is exclusive.
local function get_range_text(lines, start_line, start_col, end_line, end_col)
  local parts = {}

  if start_line == end_line then
    return lines[start_line + 1]:sub(start_col + 1, end_col)
  end

  parts[1] = lines[start_line + 1]:sub(start_col + 1)

  for line_idx = start_line + 2, end_line do
    table.insert(parts, lines[line_idx])
  end

  table.insert(parts, lines[end_line + 1]:sub(1, end_col))

  return table.concat(parts, "\n")
end

local function find_first_json_container(lines)
  local in_string = false
  local escaped = false
  local stack = {}
  local candidates = {}

  for line_idx, line in ipairs(lines) do
    local zero_based_line = line_idx - 1
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
        table.insert(stack, {
          char = char,
          line = zero_based_line,
          col = i - 1,
        })

      elseif char == "}" or char == "]" then
        if #stack > 0 then
          local opener = stack[#stack]
          local expected = opener.char == "{" and "}" or "]"

          if char == expected then
            table.remove(stack)
            table.insert(candidates, {
              start_line = opener.line,
              start_col = opener.col,
              end_line = zero_based_line,
              end_col = i,
            })
          else
            -- Discard only the mismatched opener so a valid nested
            -- container or a later candidate can still be found.
            table.remove(stack)
          end
        end
      end

      i = i + 1

      ::continue::
    end

    -- Raw newlines are not valid inside JSON strings. Reset the string
    -- state so malformed text cannot hide a later valid container.
    if in_string then
      in_string = false
      escaped = false
    end
  end

  -- Prefer the earliest candidate, then verify that it is actually JSON.
  -- Balanced delimiters alone are not enough (for example, "{not JSON}").
  table.sort(candidates, function(a, b)
    if a.start_line == b.start_line then
      return a.start_col < b.start_col
    end
    return a.start_line < b.start_line
  end)

  for _, candidate in ipairs(candidates) do
    local input = get_range_text(
      lines,
      candidate.start_line,
      candidate.start_col,
      candidate.end_line,
      candidate.end_col
    )
    local ok = pcall(vim.json.decode, input)

    if ok then
      return candidate.start_line,
        candidate.start_col,
        candidate.end_line,
        candidate.end_col
    end
  end

  return nil
end


local function get_line_indent(line)
  return line:match("^[ \t]*") or ""
end

local function get_json_depth(lines, target_line, target_col)
  local stack = {}
  local in_string = false
  local escaped = false

  for line_idx, line in ipairs(lines) do
    local zero_based_line = line_idx - 1
    local end_col = #line

    if zero_based_line == target_line then
      -- target_col points at the opening delimiter. Only count
      -- containers that surround it.
      end_col = target_col
    end

    for i = 1, end_col do
      local char = line:sub(i, i)

      if in_string then
        if escaped then
          escaped = false
        elseif char == "\\" then
          escaped = true
        elseif char == '"' then
          in_string = false
        end
      elseif char == '"' then
        in_string = true
      elseif char == "{" or char == "[" then
        table.insert(stack, char)
      elseif char == "}" or char == "]" then
        local opener = stack[#stack]
        local expected = opener == "{" and "}" or "]"

        if opener and char == expected then
          table.remove(stack)
        end
      end
    end

    if zero_based_line == target_line then
      break
    end

    -- Raw newlines are not valid inside JSON strings.
    in_string = false
    escaped = false
  end

  return #stack
end

local function format_json(data, depth, initial_depth, initial_indent)
  initial_depth = initial_depth or 0
  initial_indent = initial_indent or ""

  local function is_array(t)
    if type(t) ~= "table" then
      return false
    end

    return vim.islist(t)
  end

  local function encode(value, current_depth, current_indent)
    -- Scalars are always normal JSON.
    if type(value) ~= "table" then
      return vim.json.encode(value)
    end

    -- At or below the requested depth, emit compact JSON.
    if current_depth >= depth then
      return vim.json.encode(value)
    end

    local parts = {}
    local indent = current_indent
    local child_indent = current_indent .. "  "

    if is_array(value) then
      for i = 1, #value do
        table.insert(
          parts,
          encode(value[i], current_depth + 1, child_indent)
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
          .. encode(value[key], current_depth + 1, child_indent)
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

  return encode(data, initial_depth, initial_indent)
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

  local input = get_range_text(
    lines,
    0,
    start_col,
    #lines - 1,
    end_col
  )

  local ok, data = pcall(vim.json.decode, input)

  if not ok then
    vim.notify(
      "JsonMinifyDepth: found container is not valid JSON",
      vim.log.levels.ERROR
    )
    return false
  end

  local all_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local original_start = all_lines[start_line + 1]
  local initial_indent = get_line_indent(original_start)
  local initial_depth = get_json_depth(all_lines, start_line, start_col)

  -- A standalone fragment may not have enough surrounding JSON for the
  -- parser above to determine its depth. Use its existing indentation then.
  if initial_depth == 0 and #initial_indent > 0 then
    initial_depth = math.floor(#initial_indent / 2)
  end

  local output = format_json(
    data,
    depth,
    initial_depth,
    initial_indent
  )

  local replacement = vim.split(
    output,
    "\n",
    { plain = true }
  )

  -- Get the original first/final lines so we can preserve
  -- everything outside the JSON container.
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
    local original_start = vim.api.nvim_buf_get_lines(
      buf,
      start_line,
      start_line + 1,
      false
    )[1]
    local initial_indent = get_line_indent(original_start)
    local all_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local initial_depth = get_json_depth(
      all_lines,
      start_line,
      #initial_indent
    )

    if initial_depth == 0 and #initial_indent > 0 then
      initial_depth = math.floor(#initial_indent / 2)
    end

    local output = initial_indent
      .. format_json(
        data,
        depth,
        initial_depth,
        initial_indent
      )

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

  if not depth or depth ~= depth or depth == math.huge or depth < 0 then
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
