return {
  "nvim-tree/nvim-tree.lua",
  version = "*",
  lazy = false,
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("nvim-tree").setup({
      view = {
        width = 30,
      },
      renderer = {
        icons = {
          show = {
            git = true,
          },
        },
      },
      actions = {
        open_file = {
          quit_on_open = false,
        },
      },
      update_focused_file = {
        enable = true,
      },
    })

    vim.keymap.set("n", "<leader>t", ":NvimTreeToggle<CR>", { silent = true })
    vim.keymap.set("n", "<leader>tf", ":NvimTreeFindFile<CR>", { silent = true })
  end,
}
