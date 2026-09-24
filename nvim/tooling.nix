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
  nixfmt # nix — the style flake.nix is already written in
  stylua # lua
  prettier # ts/tsx/json/css/html/md, when a package has no local copy

  # ── CLI tools the plugins shell out to ───────────────────────────
  ripgrep # telescope find_files and live_grep
  fd
  fzf
  tree-sitter # REQUIRED by nvim-treesitter's `main` branch (>= 0.26.1)
  lazygit # <leader>gg
]

# ── Deliberately NOT here: the host toolchain ──────────────────────
#
# gcc, gnumake, curl and gnutar were in this list and have been removed,
# for the same reason rust-analyzer was never in it: on a non-NixOS distro
# `home.packages` lands in ~/.nix-profile/bin, which sits AHEAD of /usr/bin
# on PATH. Adding gcc therefore replaced the host toolchain for this user --
# gcc/cc/c++/cpp plus all of binutils (ld, as, ar, objcopy, readelf, strip,
# nm, ...), 40 shadowed binaries in total.
#
# That is not a cosmetic difference. The nixpkgs gcc is wrapped to look in
# the store for headers and libraries and does not read /usr/include, so
# anything that builds against an Arch-installed library stops compiling:
#
#   $ gcc usb.c -lusb-1.0            # nix gcc, first on PATH
#   fatal error: libusb-1.0/libusb.h: No such file or directory
#   $ /usr/bin/gcc usb.c -lusb-1.0   # Arch gcc
#   (builds and runs)
#
# which is exactly the path every -sys crate takes, since cc-rs picks up
# whatever `cc` is on PATH -- probe-rs, esp-idf host tools, and any cargo
# build with a native dependency.
#
# Arch already ships all four, at equal or newer versions (gcc 16.2.1 vs
# nixpkgs 15.3.0; make 4.4.1, curl 8.22.0 and tar 1.35 are identical), so
# nothing is lost. tree-sitter stays because Arch has no package for it, and
# it only shells out to whatever `cc` it finds -- which is now the right one.
#
# If a project needs a pinned compiler, it belongs in that project's
# devShell, reached through the direnv integration in ../home.nix, not in
# the user profile.
