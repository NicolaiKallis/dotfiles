# Everything the Neovim config expects to find on PATH.
#
# The Lua beside this file is plain Neovim config — it needs no nix. What this
# list pins is the part that actually breaks when you move machines: the
# language servers, formatters and CLI tools.
#
# Imported by ../home.nix, so it is the single source of truth for editor
# tooling. Keep it a plain function of `pkgs` rather than a flake, so it can be
# reused from a NixOS module later without another flake input.
#
# Deliberately NOT here: rust-analyzer. Inside HyRAIL it must be the build from
# that repository's rust-toolchain.toml (nightly-2026-08-28), which its own
# flake provides via direnv. A second copy on PATH is how proc-macro ABI
# mismatches start.
{ pkgs }:

with pkgs;
[
  # ── Language servers ─────────────────────────────────────────────
  # Names match the `servers` table in lua/plugins/lsp.lua one for one.
  lua-language-server # lua_ls — this config itself
  nixd # nixd — flake.nix and the NixOS modules; not in Mason
  taplo # taplo — every Cargo.toml, clippy.toml, rustfmt.toml
  marksman # marksman
  yaml-language-server # yamlls
  basedpyright # basedpyright
  typescript-language-server # ts_ls
  typescript # tsserver, for packages with no node_modules yet
  vscode-langservers-extracted # jsonls, html, cssls, eslint

  # ── Formatters ───────────────────────────────────────────────────
  # Matching lua/plugins/format.lua.
  nixfmt-rfc-style # nix — the style flake.nix is already written in
  stylua # lua
  prettier # ts/tsx/json/css/html/md, when a package has no local copy

  # ── CLI tools the plugins shell out to ───────────────────────────
  ripgrep # telescope find_files and live_grep
  fd
  fzf
  gnumake # telescope-fzf-native, LuaSnip's jsregexp
  gcc
  tree-sitter # REQUIRED by nvim-treesitter's `main` branch (>= 0.26.1)
  lazygit # <leader>gg
  curl
  gnutar
]
