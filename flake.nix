# Home Manager, standalone — this is not NixOS, it manages one user's home.
#
#   nix run home-manager/master -- switch --flake ~/dotfiles   (first time)
#   home-manager switch --flake ~/dotfiles                     (after that)
#
# With no `#name` after the flake path, home-manager picks the entry in
# homeConfigurations that matches $USER.
#
# Everything this manages lives in this repository, so a new machine is:
#   git clone <repo> ~/dotfiles && nix run home-manager/master -- switch --flake ~/dotfiles
{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # One home.nix, one entry per machine. The user and home directory are
      # the only things that differ between them, so they are the only things
      # passed in; everything in home.nix that needs the home path already goes
      # through config.home.homeDirectory.
      #
      # `home-manager switch --flake ~/dotfiles` with no `#name` picks the entry
      # matching $USER, so the same command works on every machine.
      mkHome =
        username: homeDirectory:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./home.nix
            { home = { inherit username homeDirectory; }; }
          ];
        };
    in
    {
      homeConfigurations = {
        root = mkHome "root" "/root"; # Default WSL Ubuntu
        nak = mkHome "nak" "/home/nak"; # Arch
      };
    };
}
