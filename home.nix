# The user environment, declaratively.
#
# Scope: the editor and its tooling, the shell rc, and the Hyprland desktop
#
# See the end of this file for what is still unmanaged.
{ config, pkgs, ... }:

{
  # home.username and home.homeDirectory are set per machine in flake.nix.

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

  # ── tmux ────────────────────────────────────────────────────────────────
  # Symlinked rather than generated from `programs.tmux`: the conf is already
  # written and commented, and the Nix module would mean re-expressing every
  # binding in a second syntax for no gain.
  xdg.configFile."tmux/tmux.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/tmux/tmux.conf";
  # nixpkgs tmuxPlugins.tmux-powerline, pinned by flake.lock.
  xdg.configFile."tmux/plugins/powerline".source =
    "${pkgs.tmuxPlugins.tmux-powerline}/share/tmux-plugins/powerline";
  # The plugin reads $XDG_CONFIG_HOME/tmux-powerline/config.sh. Symlinked into the repo so
  # theme and segment edits are live and show up as diffs.
  xdg.configFile."tmux-powerline".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/tmux-powerline";

  # ── git ─────────────────────────────────────────────────────────────────
  # Generated, not symlinked: this is the case where the Nix module earns its
  # keep -- it is a handful of typed options rather than an INI file.
  #
  # NOTE: ~/.gitconfig was moved to ~/.gitconfig.pre-hm-bak. Git reads
  # $XDG_CONFIG_HOME/git/config first and ~/.gitconfig second, so leaving it in
  # place would silently override everything written here.
  programs.git = {
    enable = true;
    settings.user = {
      name = "Nicolai Kallis";
      email = "nicolai.kallis@gmx.de";
    };
    # Carried over from this machine's ~/.gitconfig, which had no counterpart
    # in the incoming config. The e-mail also came from there: it collided with
    # the incoming nicolai.kallis@meanwave.com, and this one was kept on
    # request, so it is the one exception to "incoming wins".
    settings.credential.helper = "store";
    ignores = [
      "**/.claude/settings.local.json"
      "*.codex" # was already in this machine's ~/.config/git/ignore
    ];
  };

  # ── direnv ──────────────────────────────────────────────────────────────
  # `nix-direnv.enable` writes the direnvrc that used to be sourced by hand,
  # and it is what makes `use flake` in HyRAIL's .envrc cache instead of
  # re-evaluating the flake on every cd.
  #
  # The `eval "$(direnv hook zsh)"` line stays in ~/.zshrc for now: the hook is
  # only written automatically once `programs.zsh` is managed here too.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # ── lazygit ─────────────────────────────────────────────────────────────
  programs.lazygit = {
    enable = true;
    settings.os.editPreset = "nvim-remote";
  };

  # ── htop ────────────────────────────────────────────────────────────────
  # Symlinked on purpose, and the one entry here that is a compromise: htop
  # REWRITES htoprc whenever you change a setting in its UI. A generated
  # (store) file would be read-only and htop could not save. This way writes go
  # through the link into the repo, so tweaks show up as a diff.
  #
  # If htop ever replaces the file instead of writing in place, the symlink
  # becomes a regular file -- the next `switch` will say so, and re-linking is
  # deleting it and switching again.
  xdg.configFile."htop/htoprc".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/htop/htoprc";

  # ── Hyprland / waybar / kitty ───────────────────────────────────────────
  # Whole directories rather than single files
  xdg.configFile."hypr".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/hypr";

  xdg.configFile."waybar".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/waybar";

  xdg.configFile."kitty".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/kitty";

  # ── bash ────────────────────────────────────────────────────────────────
  # Symlinked, not `programs.bash`: the file is a working Arch .bashrc with
  # nvm, cargo, powerline and a zoxide init that must stay last, and
  # re-expressing that as initExtra buys nothing.
  #
  # The cost of not using `programs.bash` is that Home Manager cannot inject
  # into it, so two lines are written by hand in bash/bashrc: the
  # hm-session-vars.sh source (which is what makes home.sessionPath and
  # home.sessionVariables above take effect) and the direnv hook.
  home.file.".bashrc".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/bash/bashrc";

  # Lets `home-manager` itself be run without `nix run`.
  programs.home-manager.enable = true;

  # Still outside this file, in rough order of how little they will hurt to
  # move:
  #
  #   programs.bash     -> would replace the symlink above and let Home
  #                        Manager inject the hm-session-vars and direnv
  #                        hooks instead of bash/bashrc doing it by hand
  #   ~/.zshrc          -> a two-line stub on this machine; bash is the login
  #                        shell, so there is nothing urgent here
  #   hyprpaper/hyprlock -> typed modules exist, but the confs are already
  #                        written and commented
  #
  # Each is `programs.<x>.enable = true;` plus its settings, or the same
  # mkOutOfStoreSymlink trick if you would rather keep the dotfile verbatim.
}
