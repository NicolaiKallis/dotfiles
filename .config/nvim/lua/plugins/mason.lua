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
      require("mason-lspconfig").setup({
        ensure_installed = {
		"cssls",
		"css-variables-language-server",
		"html",
	},
        automatic_installation = true,
      })
    end
  }
}

