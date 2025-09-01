local opts = { noremap = true, silent = true }

local term_opts = { silent = true }

-- Shorten function name
local keymap = vim.api.nvim_set_keymap

--Remap space as leader key
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

-- Normal --
keymap("n", "<leader>h", ":nohl<cr>", opts)
keymap("n", "<leader>w", ":w<cr>", opts)

-- Better window navigation
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)

-- keymap("n", "<leader>e", ":CHADopen<cr>", opts)
keymap("n", "<leader>e", "<CMD>Oil --float<cr>", opts)

-- Resize with arrows
keymap("n", "<C-Up>", ":resize -2<CR>", opts)
keymap("n", "<C-Down>", ":resize +2<CR>", opts)
keymap("n", "<C-Left>", ":vertical resize -2<CR>", opts)
keymap("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- Navigate buffers
keymap("n", "<leader>bn", ":bnext<CR>", opts)
keymap("n", "<leader>bb", ":bprevious<CR>", opts)
keymap("n","<leader>c", "<cmd>bdelete<cr>", term_opts)

-- Move text up and down
keymap("n", "<A-j>", ":m .+1<CR>==", opts) -- vscode bindings taken from lunarvim
keymap("n", "<A-k>", ":m .-2<CR>==", opts) -- vscode bindings taken from lunarvim

-- Insert --
-- Press jk fast to enter
keymap("i", "jk", "<ESC>", opts)
keymap("i", "<A-j", "<Esc>:m .+1<CR>==gi", opts) -- vscode bindings taken from lunarvim
keymap("i", "<A-k", "<Esc>:m .-2<CR>==gi", opts) -- vscode bindings taken from lunarvim

-- Visual --
-- Stay in indent mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Move text up and down
keymap("v", "<A-j>", ":m .+1<CR>==", opts) -- vscode bindings taken from lunarvim
keymap("v", "<A-k>", ":m .-2<CR>==", opts) -- vscode bindings taken from lunarvim
keymap("v", "p", '"_dP', opts)

-- Visual Block --
-- Move text up and down
keymap("x", "J", ":move '>+1<CR>gv-gv", opts)
keymap("x", "K", ":move '<-2<CR>gv-gv", opts)
keymap("x", "<A-j>", ":move '>+1<CR>gv-gv", opts) -- vscode bindings taken from lunarvim
keymap("x", "<A-k>", ":move '<-2<CR>gv-gv", opts) -- vscode bindings taken from lunarvim

-- Terminal --
-- Better terminal navigation
keymap("t", "<C-h>", "<C-\\><C-N><C-w>h", term_opts)
keymap("t", "<C-j>", "<C-\\><C-N><C-w>j", term_opts)
keymap("t", "<C-k>", "<C-\\><C-N><C-w>k", term_opts)
keymap("t", "<C-l>", "<C-\\><C-N><C-w>l", term_opts)

-- Telescope
keymap("n", "<leader>f", "<cmd>lua require'telescope.builtin'.find_files(require('telescope.themes').get_dropdown({ previewer = false }))<cr>", opts)
keymap("n", "<leader>st", "<cmd>Telescope live_grep<cr>", opts)
keymap("n", "<leader>p", "<cmd>Telescope projections<cr>", opts)
keymap("n", "<leader>o", ":lua require'telescope'.extensions.project.project{}<CR>", opts)

-- Commenting
keymap("n", "<leader>/", "gcc", { noremap = false, silent = true })
keymap("v", "<leader>/", "gc", { noremap = false, silent = true })

