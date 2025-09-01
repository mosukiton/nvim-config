local opts = {
    workspaces = {                                -- Default workspaces to search for 
        -- { "~/Documents/dev", { ".git" } },        Documents/dev is a workspace. patterns = { ".git" }
        -- { "~/repos", {} },                        An empty pattern list indicates that all subdirectories are considered projects
        -- "~/dev",                                  dev is a workspace. default patterns is used (specified below)
        "~/Work"
    },
    patterns = { ".git", ".svn", ".hg" },      -- Default patterns to use if none were specified. These are NOT regexps.
    -- store_hooks = { pre = nil, post = nil },   -- pre and post hooks for store_session, callable | nil
    -- restore_hooks = { pre = nil, post = nil }, -- pre and post hooks for restore_session, callable | nil
    -- workspaces_file = "path/to/file",          -- Path to workspaces json file
    -- sessions_directory = "path/to/dir",        -- Directory where sessions are stored
}

local projections_loaded, projections = pcall(require, "projections")
if not projections_loaded then
    vim.notify("failed to load projections", vim.log.levels.ERROR)
	return
end

projections.setup(opts);

local telescope_loaded, telescope = pcall(require, "telescope")
if not telescope_loaded then
    vim.notify("failed to load telescope after loading projections", vim.log.levels.ERROR)
	return
end

telescope.load_extension('projections')
