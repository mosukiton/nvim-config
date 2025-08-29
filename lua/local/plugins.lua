local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end

vim.opt.rtp:prepend(lazypath)

local plugins = {
    { "folke/lazy.nvim" },
    { "nvim-lua/popup.nvim" },
    { "nvim-lua/plenary.nvim" },
    { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} },
    -- { "Hoffs/omnisharp-extended-lsp.nvim" },
    { "Issafalcon/lsp-overloads.nvim" },

    -- Colour schemes
    { "folke/tokyonight.nvim" },

    -- cmp plugins
    {
        "hrsh7th/nvim-cmp", -- The completion plugin
        dependencies = {
            "hrsh7th/cmp-buffer", -- buffer completions
            "hrsh7th/cmp-path", -- path completions
            "hrsh7th/cmp-cmdline", -- cmdline completions
            "saadparwaiz1/cmp_luasnip", -- snippet completions
            "hrsh7th/cmp-nvim-lsp", -- lsp completions
            "hrsh7th/cmp-nvim-lua", -- neovim lua completions
        },
        event = { "InsertEnter", "CmdlineEnter" },
        setup = function()
            return require "local.cmp"
        end
    },

    -- snippets
    {
        "L3MON4D3/LuaSnip",
        dependencies = { "rafamadriz/friendly-snippets" },
        build = "make install_jsregexp",
    },

    -- LSP
    -- simple to use language server installer
    {
        "mason-org/mason-lspconfig.nvim",
        opts = require "local.lsp.mason-lspconfig",
        dependencies = {
            { "mason-org/mason.nvim", opts = require "local.lsp.mason" },
            "neovim/nvim-lspconfig",
        },
    },
    {
        "seblyng/roslyn.nvim",
        ft = "cs",
        opts = require "local.lsp.settings.roslyn"
    },

    -- Telescope
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
        },
    },

    -- Treesitter
    {
        "nvim-treesitter/nvim-treesitter",
        event = { "BufReadPost", "BufNewFile" },
        cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
        build = ":TSUpdate",
        opts = function (plugin, opts)
            opts = require "local.treesitter"
            vim.opt.rtp:prepend(plugin.dir)
            require("nvim-treesitter.configs").setup(opts)
            vim.notify("treesitter config loaded")
            -- return require"local.treesitter"
            return opts
        end,
    },

    -- Autopairs
    {
        'windwp/nvim-autopairs',
        event = "InsertEnter",
        -- config = true,
        opts = function ()
            return require "local.autopairs"
	    end,
    },

    -- Comments
    {
        "numToStr/Comment.nvim",
        opts = function ()
            return require "local.comment.comment"
        end,
    },
    {
        "JoosepAlviste/nvim-ts-context-commentstring",
        opts = function ()
            return require "local.comment.ts-context"
        end,
    },

    -- Project and Session Management
    {
        "gnikdroy/projections.nvim",
        branch = "pre_release",
    },
    {
        'nvim-telescope/telescope-project.nvim',
        dependencies = { 'nvim-telescope/telescope.nvim' }
    },

    -- File Tree
    {
        "ms-jpq/chadtree",
        branch = "chad",
        -- cmd = "python3 -m chadtree deps"
    },


    { -- Useful plugin to show you pending keybinds.
        'folke/which-key.nvim',
        event = 'VimEnter', -- Sets the loading event to 'VimEnter'
        opts = {
            -- delay between pressing a key and opening which-key (milliseconds)
            -- this setting is independent of vim.o.timeoutlen
            delay = 750,
            icons = {
                -- set icon mappings to true if you have a Nerd Font
                mappings = vim.g.have_nerd_font,
                -- If you are using a Nerd Font: set icons.keys to an empty table which will use the
                -- default which-key.nvim defined Nerd Font icons, otherwise define a string table
                keys = vim.g.have_nerd_font and {} or {
                    Up = '<Up> ',
                    Down = '<Down> ',
                    Left = '<Left> ',
                    Right = '<Right> ',
                    C = '<C-…> ',
                    M = '<M-…> ',
                    D = '<D-…> ',
                    S = '<S-…> ',
                    CR = '<CR> ',
                    Esc = '<Esc> ',
                    ScrollWheelDown = '<ScrollWheelDown> ',
                    ScrollWheelUp = '<ScrollWheelUp> ',
                    NL = '<NL> ',
                    BS = '<BS> ',
                    Space = '<Space> ',
                    Tab = '<Tab> ',
                    F1 = '<F1>',
                    F2 = '<F2>',
                    F3 = '<F3>',
                    F4 = '<F4>',
                    F5 = '<F5>',
                    F6 = '<F6>',
                    F7 = '<F7>',
                    F8 = '<F8>',
                    F9 = '<F9>',
                    F10 = '<F10>',
                    F11 = '<F11>',
                    F12 = '<F12>',
                },
            },

            -- Document existing key chains
            spec = {
              { '<leader>s', group = '[S]earch' },
              { '<leader>t', group = '[T]oggle' },
              { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
            },
        },
    },
}

require("lazy").setup(plugins)
