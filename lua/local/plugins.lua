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
    -- Telescope
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
        },
    },

    -- Treesitter
    { -- Highlight, edit, and navigate code
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        main = "nvim-treesitter.configs", -- Sets main module to use for opts
        -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
        opts = require "local.treesitter"
        -- There are additional nvim-treesitter modules that you can use to interact
        -- with nvim-treesitter. You should go explore a few and see what interests you:
        --
        --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
        --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
        --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
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


    -- Which-Key
    {
        -- Useful plugin to show you pending keybinds.
        'folke/which-key.nvim',
        event = 'VimEnter', -- Sets the loading event to 'VimEnter'
        opts = require "local.whichkey",
    },
}

require("lazy").setup(plugins)
