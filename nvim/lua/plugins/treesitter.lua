return {
  {
    "nvim-treesitter/nvim-treesitter",
    -- Pinned to master on purpose. The default branch is now `main`, whose API
    -- dropped `nvim-treesitter.configs` entirely; cloning the default on a new
    -- machine would break this file with no obvious cause.
    branch = "master",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    main = "nvim-treesitter.configs",
    -- Repairs master's predicate/directive handlers for the 0.11+ match API.
    -- Must run after the plugin has registered its own; see the file's header.
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
      require("hyrail.ts_compat")
    end,
    opts = {
      ensure_installed = {
        -- Rust side
        "rust",
        "toml",
        -- TypeScript side: model, generator, visualizer server, React webapp
        "typescript",
        "tsx",
        "javascript",
        "jsdoc",
        "json",
        "jsonc",
        "html",
        "css",
        -- Nix: flake plus the NixOS deployments under infra/ and aurora_infra/
        "nix",
        -- Everything else that actually appears in the tree
        "python",
        "yaml",
        "markdown",
        "markdown_inline",
        "xml",
        "bash",
        "lua",
        "luadoc",
        "vim",
        "vimdoc",
        "query",
        "regex",
        "diff",
        "git_config",
        "gitcommit",
        "gitignore",
        "gitattributes",
      },
      sync_install = false,
      auto_install = false,
      highlight = {
        enable = true,
        -- defmt format strings and the generated tables get long; skip the
        -- parser on anything pathological rather than stalling the UI.
        disable = function(_, buf)
          local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
          return ok and stats and stats.size > 512 * 1024
        end,
      },
      indent = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          node_decremental = "<bs>",
        },
      },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "master",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-treesitter.configs").setup({
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
              ["aa"] = "@parameter.outer",
              ["ia"] = "@parameter.inner",
            },
          },
          move = {
            enable = true,
            set_jumps = true,
            goto_next_start = { ["]f"] = "@function.outer" },
            goto_previous_start = { ["[f"] = "@function.outer" },
          },
        },
      })
    end,
  },
}
