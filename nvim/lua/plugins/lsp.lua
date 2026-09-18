-- Language servers for everything in the tree except Rust, which rustaceanvim
-- owns (see plugins/rust.lua).
--
-- A server is only enabled when its binary is actually on PATH. That is the
-- whole portability story: this file describes intent, the environment decides
-- what is available, and `:checkhealth hyrail` says what is missing instead of
-- nvim throwing an error on every buffer.

return {
  {
    -- Types for the nvim API while editing this config. Only loads in Lua
    -- buffers that look like nvim config, so it costs nothing elsewhere.
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = { { path = "${3rd}/luv/library", words = { "vim%.uv" } } },
    },
  },

  { "b0o/schemastore.nvim", lazy = true, version = false },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "b0o/schemastore.nvim", "hrsh7th/cmp-nvim-lsp" },
    config = function()
      vim.diagnostic.config({
        virtual_text = { spacing = 2, source = "if_many" },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.HINT] = " ",
            [vim.diagnostic.severity.INFO] = " ",
          },
        },
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = { border = "rounded", source = "if_many" },
      })

      local capabilities = vim.tbl_deep_extend(
        "force",
        vim.lsp.protocol.make_client_capabilities(),
        require("cmp_nvim_lsp").default_capabilities()
      )

      ---@type table<string, table>
      local servers = {
        -- This config, and any other Lua.
        lua_ls = {
          bin = "lua-language-server",
          settings = {
            Lua = {
              workspace = { checkThirdParty = false },
              telemetry = { enable = false },
              hint = { enable = true },
              format = { enable = false }, -- stylua via conform
            },
          },
        },

        -- aurora_model, framework/modeling, framework/visualization and its
        -- React webapp. One client per package root, so each picks up its own
        -- tsconfig.json.
        --
        -- NOTE: these packages depend on each other through `file:` links
        -- (aurora_model -> hyrail-modeling). Without `npm install` having run,
        -- the server resolves no types and every import reports an error.
        ts_ls = {
          bin = "typescript-language-server",
          init_options = { hostInfo = "neovim" },
          settings = {
            typescript = {
              inlayHints = {
                includeInlayParameterNameHints = "literals",
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = false,
                includeInlayFunctionLikeReturnTypeHints = true,
              },
            },
          },
        },

        -- flake.nix, infra/ and aurora_infra/ NixOS modules.
        nixd = {
          bin = "nixd",
          settings = {
            nixd = {
              formatting = { command = { "nixfmt" } },
            },
          },
        },

        -- 76 TOML files: every Cargo.toml, both clippy.toml files, rustfmt.toml.
        -- Formatting is deliberately left off; see plugins/format.lua.
        taplo = { bin = "taplo" },

        jsonls = {
          bin = "vscode-json-language-server",
          before_init = function(_, config)
            config.settings.json.schemas = require("schemastore").json.schemas()
          end,
          settings = { json = { validate = { enable = true } } },
        },

        yamlls = {
          bin = "yaml-language-server",
          before_init = function(_, config)
            config.settings.yaml.schemas = require("schemastore").yaml.schemas()
          end,
          settings = { yaml = { keyOrdering = false } },
        },

        html = { bin = "vscode-html-language-server" },
        cssls = { bin = "vscode-css-language-server" },
        marksman = { bin = "marksman" },

        -- aurora_infra/rf/srfu_lora_sdr_receiver.py
        basedpyright = {
          bin = "basedpyright-langserver",
          settings = {
            basedpyright = {
              analysis = {
                typeCheckingMode = "basic",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "openFilesOnly",
              },
            },
          },
        },

        -- framework/modeling ships an eslint.config.mjs. Needs node_modules.
        eslint = { bin = "vscode-eslint-language-server" },
      }

      -- `bin` above is the probe, not the command: nvim-lspconfig wraps `cmd`
      -- in a function for most of these servers (so it can fall back to a TCP
      -- connection), which means the binary name cannot be read back off the
      -- resolved config. Enabling a server whose binary is absent is not
      -- harmless — nvim spawns it on every matching buffer and throws EACCES
      -- into the message area each time.
      local missing = {}
      for name, cfg in pairs(servers) do
        local bin = cfg.bin
        cfg.bin = nil
        cfg.capabilities = vim.tbl_deep_extend("force", capabilities, cfg.capabilities or {})
        vim.lsp.config(name, cfg)

        if bin == nil or vim.fn.executable(bin) == 1 then
          vim.lsp.enable(name)
        else
          table.insert(missing, string.format("%s (%s)", name, bin))
        end
      end

      -- Read by :checkhealth hyrail rather than notified at startup: a missing
      -- server should not print a banner over the file you opened.
      vim.g.hyrail_missing_servers = missing

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("hyrail_lsp_attach", { clear = true }),
        callback = function(ev)
          local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = "LSP: " .. desc })
          end

          map("n", "gd", "<cmd>Telescope lsp_definitions<cr>", "Definition")
          map("n", "gD", vim.lsp.buf.declaration, "Declaration")
          map("n", "gi", "<cmd>Telescope lsp_implementations<cr>", "Implementation")
          map("n", "gr", "<cmd>Telescope lsp_references<cr>", "References")
          map("n", "gy", "<cmd>Telescope lsp_type_definitions<cr>", "Type definition")
          map("n", "K", function() vim.lsp.buf.hover({ border = "rounded" }) end, "Hover")
          map(
            { "n", "i" },
            "<C-s>",
            function() vim.lsp.buf.signature_help({ border = "rounded" }) end,
            "Signature help"
          )
          map("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
          map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")

          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if client and client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
            map(
              "n",
              "<leader>ci",
              function()
                vim.lsp.inlay_hint.enable(
                  not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }),
                  { bufnr = ev.buf }
                )
              end,
              "Toggle inlay hints"
            )
          end
        end,
      })
    end,
  },
}
