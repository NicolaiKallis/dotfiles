-- Formatting mirrors .pre-commit-config.yaml, so a save produces what CI would
-- have produced and `pre-commit run --all-files` stays quiet.
--
-- Two deliberate gaps:
--
--   * TOML is never auto-formatted. Cargo.toml under aurora/ and aurora/nodes/
--     is written by the generator's TOML emitter (@iarna/toml), not by taplo;
--     reformatting it fights the next regeneration and shows up as a merge
--     conflict. `:Format` still works if you ask for it by hand.
--
--   * Rust goes through rust-analyzer rather than a bare `rustfmt`, because
--     rustfmt.toml sets `unstable_features = true` — the toolchain that
--     rust-analyzer already loaded is the one that can honour it.

return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo", "Format" },
    keys = {
      {
        "<leader>cf",
        function() require("conform").format({ async = true, lsp_format = "fallback" }) end,
        mode = { "n", "v" },
        desc = "Format buffer/selection",
      },
    },
    opts = {
      formatters_by_ft = {
        rust = { lsp_format = "prefer" },

        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        markdown = { "prettier" },
        yaml = { "prettier" },

        nix = { "nixfmt" },
        lua = { "stylua" },

        -- toml: intentionally empty, see the note above.
      },

      -- Only the file types whose formatting CI actually enforces run on save.
      -- Everything else is <leader>cf.
      format_on_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return nil
        end
        local on_save = { rust = true, typescript = true, lua = true, nix = true }
        if not on_save[vim.bo[bufnr].filetype] then
          return nil
        end
        return { timeout_ms = 3000, lsp_format = "prefer" }
      end,

      formatters = {
        -- prettier is pinned to 3.9.x in .pre-commit-config.yaml and the
        -- package.json files carry `"prettier": { "printWidth": 110 }`.
        -- conform prefers node_modules/.bin, so once `npm install` has run in
        -- a package, the pinned version and its config are what gets used.
        prettier = { require_cwd = false },
      },
    },
    init = function()
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

      vim.api.nvim_create_user_command("Format", function(args)
        require("conform").format({ async = true, lsp_format = "fallback" })
        local _ = args
      end, { desc = "Format the buffer" })

      vim.api.nvim_create_user_command("FormatToggle", function(args)
        if args.bang then
          vim.b.disable_autoformat = not vim.b.disable_autoformat
        else
          vim.g.disable_autoformat = not vim.g.disable_autoformat
        end
        vim.notify(
          ("format on save: %s"):format(
            (vim.g.disable_autoformat or vim.b.disable_autoformat) and "off" or "on"
          )
        )
      end, { bang = true, desc = "Toggle format on save (! for buffer only)" })
    end,
  },
}
