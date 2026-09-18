-- Rust is 508 of the ~830 source files here, spread over eight separate cargo
-- workspaces with no Cargo.toml at the repository root:
--
--   framework/runtime                      host
--   framework/runtime/examples/node-stm32h5   thumbv8m.main-none-eabihf
--   framework/runtime/examples/i2c-echo       thumbv8m.main-none-eabihf
--   aurora                                 host
--   aurora/nodes/stm32h563zi               thumbv8m.main-none-eabihf
--   aurora/nodes/stm32h563rg               thumbv8m.main-none-eabihf
--   aurora_infra/gse-fuse                  host
--   aurora_infra/logging-fuse              host
--
-- .vscode/settings.json solves this by listing five of them in
-- `linkedProjects`, because VS Code has one workspace folder and
-- rust-analyzer's auto-discovery only descends one level. nvim does not have
-- that constraint: rustaceanvim resolves the root per buffer via
-- `cargo metadata`, so all eight work and nothing has to be maintained by hand
-- when a ninth appears. The cost is one rust-analyzer process per workspace
-- you actually open.
--
-- The cross-compiled workspaces need no `cargo.target` here: each carries a
-- .cargo/config.toml with `build.target = "thumbv8m.main-none-eabihf"`, which
-- rust-analyzer reads.

return {
  {
    "mrcjkb/rustaceanvim",
    version = "^6",
    lazy = false, -- the plugin registers the filetype hook itself
    init = function()
      vim.g.rustaceanvim = {
        server = {
          -- rust-analyzer must be the one from rust-toolchain.toml
          -- (nightly-2026-08-28). A mismatched build disagrees about proc
          -- macro ABI and the libapp macros stop resolving, which looks like
          -- "half the crate is red" rather than a version error. The dev
          -- shell puts the right one first on PATH.
          cmd = function() return { "rust-analyzer" } end,

          default_settings = {
            ["rust-analyzer"] = {
              cargo = {
                -- rust-analyzer passes --all-targets by default. On the node
                -- workspaces that drags the drivers' test targets, whose
                -- dev-dependencies need std, into a thumbv8m build: it fails
                -- inside the registry crates and no diagnostic ever reaches a
                -- file of ours. Both of these matter — `cargo` drives the
                -- build-script and proc-macro pass that makes memory_map!,
                -- pinmap! and can_com! resolve at all.
                allTargets = false,

                -- Not allFeatures: libapp's `stm32` and `host` features are
                -- mutually exclusive (AGENTS.md section 6), so enabling
                -- everything fails to compile the crate at the root of the
                -- tree.
                allFeatures = false,
                buildScripts = { enable = true },
              },

              check = { command = "clippy", allTargets = false },
              checkOnSave = true,
              procMacro = { enable = true },

              -- Match rustfmt.toml so auto-import writes what the formatter
              -- would, instead of churning the file on the next save.
              imports = {
                granularity = { group = "module", enforce = true },
                group = { enable = true },
              },

              files = {
                excludeDirs = { ".direnv", ".git", "node_modules", "target", ".hyrail" },
              },

              inlayHints = {
                lifetimeElisionHints = { enable = "skip_trivial" },
                closureReturnTypeHints = { enable = "with_block" },
              },
            },
          },
        },

        tools = {
          float_win_config = { border = "rounded" },
          -- Deliberately not wired to probe-rs: flashing is a hardware action
          -- and AGENTS.md section 7 wants it to be explicit.
          enable_clippy = true,
        },
      }
    end,
    config = function()
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("hyrail_rust_keys", { clear = true }),
        pattern = "rust",
        callback = function(ev)
          local function map(lhs, action, desc)
            vim.keymap.set(
              "n",
              lhs,
              function() vim.cmd.RustLsp(action) end,
              { buffer = ev.buf, desc = "Rust: " .. desc }
            )
          end
          -- `K` twice opens the rendered rustdoc rather than the hover blurb
          map("K", "hover actions", "Hover actions")
          map("<leader>ra", "codeAction", "Code action (grouped)")
          map("<leader>rr", "runnables", "Runnables")
          map("<leader>rt", "testables", "Testables")
          map("<leader>rm", "expandMacro", "Expand macro")
          map("<leader>rp", "parentModule", "Parent module")
          map("<leader>rD", "renderDiagnostic", "Render diagnostic")
          map("<leader>re", "explainError", "Explain error")
          map("<leader>rc", "openCargo", "Open Cargo.toml")
          map("<leader>rj", "joinLines", "Join lines")
        end,
      })
    end,
  },

  -- Cargo.toml: dependency versions and "outdated" markers inline.
  {
    "saecki/crates.nvim",
    event = { "BufRead Cargo.toml" },
    opts = {
      -- The in-process language server, not the nvim-cmp source: the cmp
      -- source is deprecated upstream and prints a warning on every Cargo.toml.
      lsp = { enabled = true, actions = true, completion = true, hover = true },
    },
  },
}
