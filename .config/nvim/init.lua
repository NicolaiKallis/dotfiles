require("config.lazy")
require("lazy").setup("plugins")

-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Tabs & indentation (4 spaces, Rust convention)
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true

-- UI
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.wrap = false

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Splits
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Persistence
vim.opt.undofile = true
vim.opt.swapfile = false

-- Clipboard
vim.opt.clipboard = "unnamedplus"

-- Faster updates (for gitsigns, diagnostics)
vim.opt.updatetime = 250
