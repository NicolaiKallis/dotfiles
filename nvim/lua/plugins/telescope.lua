return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        -- Needs make + a C compiler. If either is missing lazy reports a build
        -- failure and telescope still works, just with the Lua sorter.
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function() return vim.fn.executable("make") == 1 end,
      },
    },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
      { "<leader>fr", "<cmd>Telescope resume<cr>", desc = "Resume last picker" },
      { "<leader>fd", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
      { "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document symbols" },
      {
        "<leader>fS",
        "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>",
        desc = "Workspace symbols",
      },
      { "<leader>fw", "<cmd>Telescope grep_string<cr>", desc = "Grep word under cursor" },
    },
    opts = function()
      local hyrail = require("hyrail")
      return {
        defaults = {
          prompt_prefix = "  ",
          selection_caret = " ",
          layout_strategy = "horizontal",
          layout_config = { preview_cutoff = 120, horizontal = { width = 0.9 } },
          file_ignore_patterns = hyrail.IGNORE,
          -- ripgrep is in the dev shell; fd is not, so both pickers use rg.
          vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--hidden",
            "--glob",
            "!.git/",
            "--glob",
            "!.direnv/",
            "--glob",
            "!target/",
            "--glob",
            "!node_modules/",
          },
        },
        pickers = {
          find_files = {
            find_command = {
              "rg",
              "--files",
              "--hidden",
              "--glob",
              "!.git/",
              "--glob",
              "!.direnv/",
              "--glob",
              "!target/",
              "--glob",
              "!node_modules/",
            },
          },
        },
        extensions = {
          fzf = { fuzzy = true, override_generic_sorter = true, override_file_sorter = true },
        },
      }
    end,
    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)
      pcall(telescope.load_extension, "fzf")
    end,
  },
}
