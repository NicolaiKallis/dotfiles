-- `:checkhealth hyrail` — everything this config needs from the environment,
-- and what is missing right now.

local hyrail = require("hyrail")

local M = {}

local start, ok, warn, err, info =
  vim.health.start, vim.health.ok, vim.health.warn, vim.health.error, vim.health.info

local function have(bin) return vim.fn.executable(bin) == 1 end

local function which(bin)
  return vim.fn.trim(vim.fn.system({ "sh", "-c", "command -v " .. bin .. " 2>/dev/null" }))
end

local function run(cmd)
  local out = vim.system(cmd, { text = true }):wait()
  if out.code ~= 0 then
    return nil
  end
  return vim.fn.trim(out.stdout or "")
end

--- @param spec { bin: string, why: string, hard: boolean }[]
local function report_tools(spec)
  for _, t in ipairs(spec) do
    if have(t.bin) then
      ok(("%s — %s"):format(t.bin, which(t.bin)))
    elseif t.hard then
      err(("%s missing — %s"):format(t.bin, t.why))
    else
      warn(("%s missing — %s"):format(t.bin, t.why))
    end
  end
end

function M.check()
  start("neovim")
  if vim.fn.has("nvim-0.11") == 1 then
    ok("nvim " .. tostring(vim.version()))
  else
    err("this config expects nvim 0.11 or newer (vim.lsp.config, vim.diagnostic.jump)")
  end

  if vim.fn.has("clipboard") == 1 or vim.g.clipboard then
    ok("clipboard provider available")
  else
    warn(
      "no clipboard provider — `clipboard = unnamedplus` will silently do nothing.\n"
        .. "On WSL install win32yank, or wl-clipboard / xclip on a Linux desktop."
    )
  end

  start("general tooling")
  report_tools({
    { bin = "git", why = "gitsigns, lazygit, lazy.nvim", hard = true },
    { bin = "rg", why = "telescope find_files and live_grep", hard = true },
    { bin = "make", why = "telescope-fzf-native and LuaSnip's jsregexp", hard = false },
    { bin = "gcc", why = "compiling telescope-fzf-native", hard = false },
    { bin = "lazygit", why = "<leader>gg", hard = false },
  })

  start("HyRAIL repository")
  local root = hyrail.root()
  if not root then
    info("not inside a HyRAIL checkout — repository checks skipped")
  else
    ok("repository root: " .. root)

    if vim.env.IN_NIX_SHELL then
      ok(("inside the nix dev shell (IN_NIX_SHELL=%s)"):format(vim.env.IN_NIX_SHELL))
    else
      warn(
        "not inside the nix dev shell.\n"
          .. "The pinned toolchain is what rust-analyzer must use. Start nvim from a\n"
          .. "shell where direnv has loaded the flake (`cd "
          .. root
          .. "`), or run\n"
          .. "`nix develop -c nvim`."
      )
    end

    -- Rust: the toolchain and rust-analyzer have to be the same build.
    local channel
    for line in io.lines(root .. "/rust-toolchain.toml") do
      channel = channel or line:match('^%s*channel%s*=%s*"([^"]+)"')
    end
    if channel then
      info("rust-toolchain.toml pins " .. channel)
    end

    if have("rust-analyzer") and have("cargo") then
      local ra, cargo = which("rust-analyzer"), which("cargo")
      if vim.fs.dirname(ra) == vim.fs.dirname(cargo) then
        ok(("rust-analyzer and cargo come from the same toolchain (%s)"):format(vim.fs.dirname(ra)))
      else
        warn(
          ("rust-analyzer (%s) and cargo (%s) are from different toolchains.\n"):format(ra, cargo)
            .. "A proc-macro ABI mismatch makes libapp's memory_map!/pinmap!/can_com!\n"
            .. "fail to expand, which looks like half the crate being red."
        )
      end
      info(run({ "rust-analyzer", "--version" }) or "rust-analyzer --version failed")
    else
      err("cargo and/or rust-analyzer not on PATH — Rust support is off")
    end

    -- Node: 22.18+ for native type stripping, and 25 breaks the visualizer.
    if have("node") then
      local v = run({ "node", "--version" }) or ""
      local major = tonumber(v:match("^v(%d+)"))
      if major and major >= 22 and major < 25 then
        ok("node " .. v)
      elseif major then
        warn(
          ("node %s — README asks for 22 LTS (22.18+); 25 is known to break\n"):format(v)
            .. "the visualizer build. LSP still works, `npm run build:all` may not."
        )
      end
    else
      err("node missing — no TypeScript support")
    end

    -- ts_ls resolves nothing useful until the workspaces are installed: the
    -- packages link to each other with `file:` dependencies.
    local pkgs = {
      "framework/modeling",
      "framework/visualization",
      "framework/visualization/webapp",
      "aurora_model",
      "aurora_infra/gse-viz",
    }
    local uninstalled = {}
    for _, p in ipairs(pkgs) do
      if vim.uv.fs_stat(root .. "/" .. p .. "/node_modules") == nil then
        table.insert(uninstalled, p)
      end
    end
    if #uninstalled == 0 then
      ok("node_modules present in every TypeScript package")
    else
      warn(
        "no node_modules in:\n  "
          .. table.concat(uninstalled, "\n  ")
          .. "\nts_ls will report unresolved imports and give no cross-package types.\n"
          .. "Fix: run `npm install` in each (modeling first — the others link to it)."
      )
    end
  end

  start("language servers")
  local missing = vim.g.hyrail_missing_servers
  if missing == nil then
    info("nvim-lspconfig has not loaded yet — open a file and re-run")
  elseif #missing == 0 then
    ok("every configured server was found on PATH")
  else
    for _, m in ipairs(missing) do
      warn(m .. " not found — that language has no LSP in this session")
    end
    info("Install via :Mason, or add the package to a dev shell / home-manager profile.")
  end

  start("formatters")
  report_tools({
    {
      bin = "prettier",
      why = ".ts/.tsx/.json/.css — pre-commit runs prettier 3.9.5",
      hard = false,
    },
    { bin = "nixfmt", why = "flake.nix and the NixOS modules", hard = false },
    { bin = "stylua", why = "this config's own Lua", hard = false },
  })
  info(
    "prettier is normally resolved from a package's node_modules/.bin, so a\n"
      .. "missing global copy is fine once `npm install` has run."
  )

  start("hardware / debugging")
  if have("probe-rs") then
    ok("probe-rs — " .. which("probe-rs"))
    info(run({ "probe-rs", "--version" }) or "")
  else
    warn("probe-rs not on PATH — :HyRailFlash and :HyRailRtt will not work")
  end

  if root then
    local nodes = require("hyrail.nodes").all()
    local built = 0
    for _, n in ipairs(nodes) do
      if vim.uv.fs_stat(n.binary) then
        built = built + 1
      end
    end
    if #nodes > 0 then
      ok(("%d node binaries discovered, %d built (:HyRailNodes to list)"):format(#nodes, built))
    else
      warn("no node binaries found under aurora/nodes/")
    end
  end

  info(
    "Flashing is never automatic: :HyRailFlash (<leader>dd) asks before it\n"
      .. "writes, and :HyRailRtt (<leader>da) only reads a running board."
  )
end

return M
