local roslyn_auto_insert_group = vim.api.nvim_create_augroup("roslyn-auto-insert", { clear = true })

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    local bufnr = args.buf

    if not client or (client.name ~= "roslyn" and client.name ~= "roslyn_ls") then
      return
    end

    -- Recreate the buffer-local handler on every attach so a restarted
    -- client replaces the old closure instead of adding a duplicate.
    vim.api.nvim_clear_autocmds({ group = roslyn_auto_insert_group, buffer = bufnr })
    vim.api.nvim_create_autocmd("InsertCharPre", {
      desc = "Roslyn: Trigger an auto insert on '/'.",
      group = roslyn_auto_insert_group,
      buffer = bufnr,
      callback = function()
        local char = vim.v.char

        if char ~= "/" then
          return
        end

        local row, col = unpack(vim.api.nvim_win_get_cursor(0))
        row = row - 1
        local character = vim.lsp.util.character_offset(bufnr, row, col, client.offset_encoding) + 1
        local uri = vim.uri_from_bufnr(bufnr)

        local params = {
          _vs_textDocument = { uri = uri },
          _vs_position = { line = row, character = character },
          _vs_ch = char,
          _vs_options = {
            tabSize = vim.bo[bufnr].tabstop,
            insertSpaces = vim.bo[bufnr].expandtab,
          },
        }

        -- InsertCharPre runs before the slash is inserted. Defer the request
        -- so Roslyn sees the changed buffer before returning an edit.
        vim.defer_fn(function()
          client:request(
            ---@diagnostic disable-next-line: param-type-mismatch
            "textDocument/_vs_onAutoInsert",
            params,
            function(err, result, _)
              local text_edit = result and result._vs_textEdit
              if err or not text_edit or not text_edit.newText then
                return
              end

              vim.snippet.expand(text_edit.newText)
            end,
            bufnr
          )
        end, 1)
      end,
    })
  end,
})

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})
