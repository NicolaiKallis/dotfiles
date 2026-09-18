-- Leaders first: lazy.nvim and every `keys =` spec read them at load time.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Set to false on a machine where Mason's prebuilt binaries do not run
-- (NixOS without nix-ld) or where every server comes from a dev shell.
if vim.g.use_mason == nil then
  -- `nix develop ~/.config/nvim` exports NVIM_USE_MASON=0, since Mason's
  -- prebuilt binaries do not run on NixOS without nix-ld.
  vim.g.use_mason = vim.env.NVIM_USE_MASON ~= "0"
end

-- Mason prepends this itself, but only once mason.nvim has loaded -- and it
-- loads lazily, after lua/plugins/lsp.lua has already probed for each server's
-- binary. Doing it here decouples the two: PATH is correct before any plugin
-- runs, and this still works if mason.nvim is disabled or absent.
if vim.g.use_mason then
  local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
  if vim.uv.fs_stat(mason_bin) then
    vim.env.PATH = mason_bin .. ":" .. vim.env.PATH
  end
end

local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Indentation. 4 spaces suits Rust; per-filetype overrides live in autocmds.
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true

-- UI
opt.signcolumn = "yes"
opt.cursorline = true
opt.termguicolors = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.fillchars:append({ eob = " " })
opt.splitright = true
opt.splitbelow = true

-- rustfmt.toml pins max_width = 100 and prettier runs at 110; the ruler shows
-- both so a line that is about to be wrapped is visible before saving.
opt.colorcolumn = "100,110"

-- Search
opt.ignorecase = true
opt.smartcase = true

-- Persistence
opt.undofile = true
opt.swapfile = false

-- WSL: nvim finds clip.exe / win32yank on its own. If :checkhealth hyrail
-- reports no clipboard tool, this line is what silently does nothing.
opt.clipboard = "unnamedplus"

-- gitsigns and diagnostics both key off CursorHold
opt.updatetime = 250

-- Ask before sourcing a repo-local .nvim.lua / .exrc. HyRAIL does not ship one
-- yet; this is what would pick it up if it did.
opt.exrc = true
