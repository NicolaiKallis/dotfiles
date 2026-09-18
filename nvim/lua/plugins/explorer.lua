-- nvim-tree, carried over from the previous config. The git-refresh wiring
-- (write, focus regain, lazygit close) is kept as it was — it is the part that
-- keeps the tree's git column honest when changes happen outside nvim.
return {
  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>t", "<cmd>NvimTreeToggle<cr>", desc = "Toggle tree" },
      { "<leader>tf", "<cmd>NvimTreeFindFile<cr>", desc = "Reveal file in tree" },
    },
    config = function()
      require("nvim-tree").setup({
        sync_root_with_cwd = true,
        respect_buf_cwd = true,
        filesystem_watchers = { enable = true, debounce_delay = 50 },
        view = { width = 34 },
        git = { enable = true, show_on_dirs = true, show_on_open_dirs = true, timeout = 1000 },
        filters = {
          git_ignored = false,
          custom = { "^%.git$", "^%.direnv$", "^node_modules$", "^target$" },
        },
        renderer = {
          decorators = {
            "Git",
            "Open",
            "Hidden",
            "Modified",
            "Bookmark",
            "Diagnostics",
            "Copied",
            "Cut",
          },
          highlight_git = "all",
          icons = {
            git_placement = "before",
            show = { file = true, folder = true, folder_arrow = true, git = true },
            glyphs = {
              git = {
                unstaged = "M",
                staged = "S",
                unmerged = "U",
                renamed = "R",
                untracked = "?",
                deleted = "D",
              },
            },
          },
        },
        actions = {
          remove_file = { close_window = true },
          open_file = { quit_on_open = false },
        },
        update_focused_file = { enable = true, update_root = { enable = true } },
        on_attach = function(bufnr)
          local api = require("nvim-tree.api")
          api.config.mappings.default_on_attach(bufnr)
          vim.keymap.set(
            "n",
            "d",
            function()
              api.fs.remove()
              vim.defer_fn(function() api.tree.reload() end, 100)
            end,
            { buffer = bufnr, noremap = true, silent = true, desc = "Delete file and refresh tree" }
          )
        end,
      })

      local group = vim.api.nvim_create_augroup("hyrail_tree_git", { clear = true })

      -- Refresh after any write so the git column is always fresh
      vim.api.nvim_create_autocmd("BufWritePost", {
        group = group,
        callback = function()
          vim.defer_fn(function() require("nvim-tree.api").tree.reload() end, 100)
        end,
      })

      -- Refresh on focus regain: covers closing lazygit, switching tmux panes
      vim.api.nvim_create_autocmd("FocusGained", {
        group = group,
        callback = function() require("nvim-tree.api").tree.reload() end,
      })

      -- lazygit: track the terminal buffer explicitly so TermClose is reliable
      local lazygit_buf = nil
      vim.api.nvim_create_autocmd("TermOpen", {
        group = group,
        callback = function(ev)
          if vim.api.nvim_buf_get_name(ev.buf):match("lazygit") then
            lazygit_buf = ev.buf
          end
        end,
      })
      vim.api.nvim_create_autocmd("TermClose", {
        group = group,
        callback = function(ev)
          local name = vim.api.nvim_buf_get_name(ev.buf)
          if ev.buf == lazygit_buf or name:match("lazygit") then
            lazygit_buf = nil
            vim.defer_fn(function() require("nvim-tree.api").tree.reload() end, 200)
          end
        end,
      })
    end,
  },
}
