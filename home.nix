# The user environment, declaratively.
#
# Scope today is deliberately small: the editor and the tools it needs. Nothing
# that already works (zsh/oh-my-zsh, git, tmux, lazygit) has been taken over
# yet — moving those in is a separate, reversible step each time. See the end of
# this file for where they go.
{ config, pkgs, ... }:

{
  home.username = "root";
  home.homeDirectory = "/root";

  # The Home Manager release this config was written against. It pins
  # backwards-compatible defaults; do not bump it casually.
  home.stateVersion = "25.11";

  # Language servers, formatters and CLI tools. One list, shared with anything
  # else that needs it later (a NixOS module, a dev shell).
  home.packages = import ./nvim/tooling.nix { inherit pkgs; };

  # The config is symlinked OUT of the nix store, not copied into it. A store
  # path would be read-only and would need `home-manager switch` after every
  # keystroke; this way ~/.config/nvim points straight at the working tree and
  # edits are live. The tradeoff is that the Lua is not itself pinned by nix —
  # git and lazy-lock.json do that job instead.
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/nvim";

  # ~/dotfiles/bin on PATH, for small scripts that are not worth a derivation.
  home.sessionPath = [ "${config.home.homeDirectory}/dotfiles/bin" ];

  # Mason's prebuilt binaries are dynamically linked against a libc layout
  # NixOS does not provide. Everything above comes from nix instead, so the
  # config skips Mason entirely (read in lua/config/options.lua).
  home.sessionVariables.NVIM_USE_MASON = "0";

  # Lets `home-manager` itself be run without `nix run`.
  programs.home-manager.enable = true;

  # Next candidates, in rough order of how little they will hurt to move:
  #
  #   programs.git      -> ~/.config/git
  #   programs.lazygit  -> ~/.config/lazygit
  #   programs.tmux     -> ~/.config/tmux
  #   programs.direnv   -> replaces the hand-written hook in ~/.zshrc
  #   programs.zsh      -> last; oh-my-zsh works and is the most disruptive
  #
  # Each is `programs.<x>.enable = true;` plus its settings, or the same
  # mkOutOfStoreSymlink trick if you would rather keep the dotfile verbatim.
}
