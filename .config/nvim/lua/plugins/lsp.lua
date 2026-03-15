return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      vim.diagnostic.config({
        virtual_text = true,
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })

      local capabilities = vim.tbl_deep_extend(
        "force",
        vim.lsp.protocol.make_client_capabilities(),
        require("cmp_nvim_lsp").default_capabilities()
      )

      local servers = { "lua_ls", "pyright", "html", "cssls", "ts_ls" }

      for _, server in ipairs(servers) do
        vim.lsp.config[server] = { capabilities = capabilities }
        vim.lsp.enable(server)
      end

      -- 4. Rust Analyzer (Custom Config)
      vim.lsp.config["rust_analyzer"] = {
        capabilities = capabilities,
        cmd = { vim.fn.expand("~/.cargo/bin/rust-analyzer") },
        settings = {
          ["rust-analyzer"] = {
            cargo = { allFeatures = true },
            checkOnSave = { command = "clippy" },
            completion = { postfix = { enable = true } },
          },
        },
      }
      vim.lsp.enable("rust_analyzer")

      -- LSP keybindings (only active when LSP is attached)
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
        callback = function(ev)
          local opts = { buffer = ev.buf }

          -- Navigation
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, opts)

          -- Documentation
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
          vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, opts)

          -- Actions
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

          -- Diagnostics
          vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
          vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
          vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)

          -- Inlay hints toggle
          vim.keymap.set("n", "<leader>ih", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }), { bufnr = ev.buf })
          end, opts)

          -- Enable inlay hints by default
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if client and client.supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
          end

          -- Format on save
          if client and client.supports_method("textDocument/formatting") then
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = vim.api.nvim_create_augroup("LspFormat." .. ev.buf, { clear = true }),
              buffer = ev.buf,
              callback = function()
                vim.lsp.buf.format({ bufnr = ev.buf })
              end,
            })
          end
        end,
      })

      -- 5. Ada (The new addition)
      vim.lsp.config["ada_ls"] = {
        capabilities = capabilities,
        cmd = { "ada_language_server" },
        filetypes = { "ada", "adb", "ads", "gpr" },
        root_markers = { "alire.toml", ".git", "*.gpr" },
      }
      vim.lsp.enable("ada_ls")

    end,
  },
}
