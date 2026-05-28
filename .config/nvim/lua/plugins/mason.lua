return {
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    config = true
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      local lsp_servers = require("config.lsp_servers")

      require("mason-lspconfig").setup({
        ensure_installed = lsp_servers.mason,
        automatic_installation = true,
      })
    end
  }
}
