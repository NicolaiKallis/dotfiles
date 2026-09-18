local hyrail = require("hyrail")

local function augroup(name) return vim.api.nvim_create_augroup("hyrail_" .. name, { clear = true }) end

-- Flash yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("yank"),
  callback = function() vim.hl.on_yank({ timeout = 150 }) end,
})

-- Per-filetype indentation. Rust and Python keep the 4-space default; the
-- TypeScript side is prettier's 2.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("indent"),
  pattern = {
    "typescript",
    "typescriptreact",
    "javascript",
    "javascriptreact",
    "json",
    "jsonc",
    "yaml",
    "html",
    "css",
    "lua",
    "nix",
    "toml",
    "markdown",
  },
  callback = function()
    vim.bo.shiftwidth = 2
    vim.bo.tabstop = 2
  end,
})

-- The CMSIS register description in .vscode is XML; nothing maps that suffix.
vim.filetype.add({
  extension = { svd = "xml" },
  filename = { [".envrc"] = "sh" },
})

-- Hard stop on the three generator-owned files. Read-only rather than a
-- warning: a stray `x` in manifest.json breaks the next regeneration, and the
-- damage is not visible until then.
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("protected"),
  callback = function(ev)
    local name = vim.api.nvim_buf_get_name(ev.buf)
    if hyrail.is_protected(name) then
      vim.bo[ev.buf].readonly = true
      vim.bo[ev.buf].modifiable = false
      vim.notify(
        "Generated merge state — regenerate instead of editing (AGENTS.md section 5)",
        vim.log.levels.WARN
      )
    end
  end,
})

-- Restore the last cursor position
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("lastpos"),
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    local lines = vim.api.nvim_buf_line_count(ev.buf)
    if mark[1] > 0 and mark[1] <= lines then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Close throwaway buffers with `q`
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_q"),
  pattern = { "help", "qf", "man", "checkhealth", "lspinfo", "startuptime" },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = ev.buf, silent = true })
  end,
})
