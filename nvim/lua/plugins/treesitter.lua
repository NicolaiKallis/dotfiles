-- nvim-treesitter, `main` branch.
--
-- `master` is archived: its own README says "Neovim 0.10 or 0.11 (Neovim 0.12
-- is not supported)", its last feature commit was 2025-05-12, and it still asks
-- core for the pre-0.11 `opts.all = false` shim that 0.12 removed -- which broke
-- every Markdown buffer with a fenced code block.
--
-- `main` is a rewrite by the same maintainer, not a fork. It is a much smaller
-- plugin: it installs parsers and ships queries, and that is all. Highlighting,
-- folding and indentation are Neovim's own features now, enabled per buffer
-- below rather than by a `modules` table.
--
-- Requires tree-sitter-cli >= 0.26.1 on PATH (see ../../tooling.nix).

-- Parsers for what is actually in the HyRAIL tree, plus the ones needed to read
-- help and git output. These are parser names, not filetypes.
local ENSURE = {
  -- Rust side
  "rust",
  "toml",
  -- TypeScript side: model, generator, visualizer server, React webapp
  "typescript",
  "tsx",
  "javascript",
  "jsdoc",
  "json", -- `main` has no separate jsonc parser; json covers .jsonc
  "html",
  "css",
  -- Nix: the flake plus the NixOS deployments under infra/ and aurora_infra/
  "nix",
  -- Everything else that appears in the tree
  "python",
  "yaml",
  "markdown",
  "markdown_inline",
  "xml", -- .vscode/STM32H563.svd
  "bash",
  -- Editing this config, and reading help/git
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
}

-- Treesitter is not worth it past this size. The CMSIS register description in
-- .vscode is 15 MB of XML; parsing it stalls the UI for seconds.
local MAX_FILESIZE = 512 * 1024

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    -- `main` does not support lazy-loading; upstream is explicit about it.
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")
      ts.setup({})

      -- Asynchronous and a no-op for parsers already present, so this is cheap
      -- on every start but still self-healing on a fresh machine.
      local installed = {}
      for _, lang in ipairs(ts.get_installed()) do
        installed[lang] = true
      end
      local missing = vim.tbl_filter(function(lang) return not installed[lang] end, ENSURE)
      if #missing > 0 then
        vim.notify(("treesitter: installing %d parser(s)"):format(#missing), vim.log.levels.INFO)
        ts.install(missing)
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("hyrail_treesitter", { clear = true }),
        callback = function(ev)
          -- Filetype -> parser. Returns the filetype itself when there is no
          -- special mapping, which is why `svd -> xml` in autocmds.lua is
          -- enough to get XML highlighting on the register description.
          local lang = vim.treesitter.language.get_lang(ev.match)
          if not lang then
            return
          end

          local path = vim.api.nvim_buf_get_name(ev.buf)
          local stat = path ~= "" and vim.uv.fs_stat(path) or nil
          if stat and stat.size > MAX_FILESIZE then
            return
          end

          -- Fails when the parser is not installed yet; that is the normal
          -- state on a first start while install() is still running.
          if not pcall(vim.treesitter.start, ev.buf, lang) then
            return
          end

          -- Folds come from treesitter, but nothing starts folded.
          vim.wo[0][0].foldmethod = "expr"
          vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"

          -- Indentation is still marked experimental upstream. It matters less
          -- here than it looks: rustfmt and prettier rewrite the file on save
          -- anyway, so this only has to be sane while typing.
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })

      vim.o.foldlevelstart = 99
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = {
          lookahead = true,
          selection_modes = {
            ["@function.outer"] = "V",
            ["@class.outer"] = "V",
            ["@parameter.outer"] = "v",
          },
        },
        move = { set_jumps = true },
      })

      local select = require("nvim-treesitter-textobjects.select")
      local move = require("nvim-treesitter-textobjects.move")

      -- `main` sets no keymaps of its own; every one of these is explicit.
      local objects = {
        f = "@function",
        c = "@class",
        a = "@parameter",
      }
      for key, query in pairs(objects) do
        vim.keymap.set(
          { "x", "o" },
          "a" .. key,
          function() select.select_textobject(query .. ".outer", "textobjects") end,
          { desc = "Select around " .. query }
        )
        vim.keymap.set(
          { "x", "o" },
          "i" .. key,
          function() select.select_textobject(query .. ".inner", "textobjects") end,
          { desc = "Select inside " .. query }
        )
      end

      vim.keymap.set(
        { "n", "x", "o" },
        "]f",
        function() move.goto_next_start("@function.outer", "textobjects") end,
        { desc = "Next function" }
      )
      vim.keymap.set(
        { "n", "x", "o" },
        "[f",
        function() move.goto_previous_start("@function.outer", "textobjects") end,
        { desc = "Previous function" }
      )
      vim.keymap.set(
        { "n", "x", "o" },
        "]c",
        function() move.goto_next_start("@class.outer", "textobjects") end,
        { desc = "Next class/impl" }
      )
      vim.keymap.set(
        { "n", "x", "o" },
        "[c",
        function() move.goto_previous_start("@class.outer", "textobjects") end,
        { desc = "Previous class/impl" }
      )
    end,
  },
}
