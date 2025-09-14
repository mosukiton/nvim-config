---@module "csvview"
---@type CsvView.Options
return {
    view = {
        display_mode = "border",
        header_lnum = true,  -- Auto-detect header (default)
        sticky_header = {
            enabled = true,
            separator = "─",  -- Separator line character
        },
    },
    parser = {
        comments = { "#", "//" },
        delimiter = {
            ft = {
                csv = ",",        -- Always use comma for .csv files
                tsv = "\t",       -- Always use tab for .tsv files
            },
            fallbacks = {       -- Try these delimiters in order for other files
                ",",              -- Comma (most common)
                "\t",             -- Tab
                ";",              -- Semicolon
                "|",              -- Pipe
                ":",              -- Colon
                " ",              -- Space
            },
        },
    },
    keymaps = {
        -- Text objects for selecting fields
        textobject_field_inner = { "if", mode = { "o", "x" } },
        textobject_field_outer = { "af", mode = { "o", "x" } },
        -- Excel-like navigation:
        -- Use <Tab> and <S-Tab> to move horizontally between fields.
        -- Use <Enter> and <S-Enter> to move vertically between rows and place the cursor at the end of the field.
        -- Note: In terminals, you may need to enable CSI-u mode to use <S-Tab> and <S-Enter>.
        jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
        jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
        jump_next_row = { "<Enter>", mode = { "n", "v" } },
        jump_prev_row = { "<S-Enter>", mode = { "n", "v" } },
    },
}
