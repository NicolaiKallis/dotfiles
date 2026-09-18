return {
  { "nvim-tree/nvim-web-devicons", lazy = true },

  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = function()
      local hyrail = require("hyrail")

      -- Which of the eight cargo workspaces the current buffer belongs to.
      -- With per-workspace rust-analyzer clients this is the difference
      -- between "why are there no diagnostics" and "wrong workspace".
      local function workspace()
        local buf = vim.api.nvim_get_current_buf()
        for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf, name = "rust-analyzer" })) do
          if client.root_dir then
            local root = hyrail.root()
            local dir = client.root_dir
            if root and dir:sub(1, #root) == root then
              dir = dir:sub(#root + 2)
            end
            return "󱘗 " .. (dir ~= "" and dir or "/")
          end
        end
        return ""
      end

      return {
        options = {
          icons_enabled = true,
          theme = "auto",
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
          globalstatus = true,
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff", "diagnostics" },
          lualine_c = { { "filename", path = 1 } },
          lualine_x = { workspace, "encoding", "filetype" },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
        inactive_sections = {
          lualine_c = { { "filename", path = 1 } },
          lualine_x = { "location" },
        },
        extensions = { "nvim-tree", "trouble", "lazy" },
      }
    end,
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "helix",
      spec = {
        { "<leader>f", group = "find" },
        { "<leader>g", group = "git" },
        { "<leader>c", group = "code" },
        { "<leader>d", group = "debug (probe-rs)" },
        { "<leader>x", group = "diagnostics" },
        { "<leader>t", group = "tree" },
        { "<leader>r", group = "rust / rename" },
        { "<leader>h", group = "hunk" },
      },
    },
    keys = {
      {
        "<leader>?",
        function() require("which-key").show({ global = false }) end,
        desc = "Buffer keymaps",
      },
    },
  },
}
