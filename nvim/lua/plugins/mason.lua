-- Mason is the fallback path, not the primary one.
--
-- Inside this repository the servers that matter come from the nix dev shell:
-- rust-analyzer in particular MUST be the pinned nightly from
-- rust-toolchain.toml, and Mason's copy would be a different build. Mason
-- fills in the rest on a machine with no nix.
--
-- Set `vim.g.use_mason = false` (in lua/config/options.lua) on NixOS or
-- anywhere Mason's prebuilt, dynamically linked binaries will not run.
return {
  {
    "mason-org/mason.nvim",
    cond = function() return vim.g.use_mason ~= false end,
    cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonLog" },
    build = ":MasonUpdate",
    opts = { ui = { border = "rounded" } },
  },

  {
    "mason-org/mason-lspconfig.nvim",
    cond = function() return vim.g.use_mason ~= false end,
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
    opts = {
      -- lua/plugins/lsp.lua decides what is enabled, after checking the binary
      -- exists. Letting mason-lspconfig enable things too would start servers
      -- twice with different settings.
      automatic_enable = false,
      ensure_installed = {
        "lua_ls",
        "ts_ls",
        "jsonls",
        "yamlls",
        "taplo",
        "html",
        "cssls",
        "marksman",
        "basedpyright",
        "eslint",
        -- Not listed: rust_analyzer (toolchain-pinned, so it comes from the
        -- dev shell) and nixd (not in the Mason registry at all -- on a nix
        -- machine it comes from the profile or a dev shell, and a non-nix
        -- machine has no .nix files worth editing).
      },
    },
  },
}
