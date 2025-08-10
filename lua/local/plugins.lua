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
    { "neovim/nvim-lspconfig" }, -- enable LSP
    { "williamboman/mason.nvim" }, -- simple to use language server installer
    { "williamboman/mason-lspconfig.nvim" }, -- simple to use language server installer
    { "jose-elias-alvarez/null-ls.nvim" }, -- LSP diagnostics and code actions
    {
        "seblyng/roslyn.nvim",
        ft = "cs",
        ---@module 'roslyn.config'
        ---@type RoslynNvimConfig
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
}

require("lazy").setup(plugins)
