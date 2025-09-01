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
    { "nvim-lua/plenary.nvim" },
    { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} },

    -- Colour schemes
    { "folke/tokyonight.nvim" },

    -- LSP
    -- simple to use language server installer
    {
        -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
        -- used for completion, annotations and signatures of Neovim apis
        'folke/lazydev.nvim',
        ft = 'lua',
        opts = {
            library = {
                -- Load luvit types when the `vim.uv` word is found
                { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
            },
        },
    },
    {
        'neovim/nvim-lspconfig',
        dependencies = {
            -- Automatically install LSPs and related tools to stdpath for Neovim
            -- Mason must be loaded before its dependents so we need to set it up here.
            -- NOTE: `opts = {}` is the same as calling `require('mason').setup({})`
            { 'mason-org/mason.nvim', opts = {} },
            'mason-org/mason-lspconfig.nvim',
            'WhoIsSethDaniel/mason-tool-installer.nvim',

            -- Useful status updates for LSP.
            { "j-hui/fidget.nvim", opts = {} },

            -- Allows extra capabilities provided by blink.cmp
            'saghen/blink.cmp',
        },
        config = require("local.lsp.init").config
    },
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
    },

    -- Telescope
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
        },
    },

    -- Autocompletion
    {
        'saghen/blink.cmp',
        event = 'VimEnter',
        version = '1.*',
        dependencies = {
            -- Snippet Engine
            {
                'L3MON4D3/LuaSnip',
                version = '2.*',
                build = (function()
                    -- Build Step is needed for regex support in snippets.
                    -- This step is not supported in many windows environments.
                    -- Remove the below condition to re-enable on windows.
                    if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
                        return
                    end
                    return 'make install_jsregexp'
                end)(),
                dependencies = {
                    -- `friendly-snippets` contains a variety of premade snippets.
                    --        See the README about individual language/framework/plugin snippets:
                    --        https://github.com/rafamadriz/friendly-snippets
                    {
                        'rafamadriz/friendly-snippets',
                        config = function()
                            require('luasnip.loaders.from_vscode').lazy_load()
                        end,
                    },
                },
                opts = {},
            },
            'folke/lazydev.nvim',
        },
        --- @module 'blink.cmp'
        --- @type blink.cmp.Config
        opts = require("local.blink-cmp"),
    },
    {
        "ray-x/lsp_signature.nvim",
        event = "InsertEnter",
        opts = require("local.lsp.lsp_signature"),
    },

    -- Treesitter
    { -- Highlight, edit, and navigate code
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        build = ":TSUpdate",
        -- main = "nvim-treesitter.configs", -- Sets main module to use for opts
        opts = require "local.treesitter"
    },

    -- Autopairs
    {
        'windwp/nvim-autopairs',
        event = "InsertEnter",
        -- config = true,
        opts = require "local.autopairs",
    },

    -- Comments
    {
        "numToStr/Comment.nvim",
        opts = function ()
           return require("local.comment.comment")
        end
    },
    {
        "JoosepAlviste/nvim-ts-context-commentstring",
        opts = function ()
           return require "local.comment.ts-context"
        end
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


    -- Which-Key
    {
        -- Useful plugin to show you pending keybinds.
        'folke/which-key.nvim',
        event = 'VimEnter', -- Sets the loading event to 'VimEnter'
        opts = require "local.whichkey",
    },
}

require("lazy").setup(plugins)
