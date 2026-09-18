# Home Manager, standalone — this is not NixOS, it manages one user's home.
#
#   nix run home-manager/master -- switch --flake ~/dotfiles#root   (first time)
#   home-manager switch --flake ~/dotfiles#root                     (after that)
#
# Everything this manages lives in this repository, so a new machine is:
#   git clone <repo> ~/dotfiles && nix run home-manager/master -- switch --flake ~/dotfiles#root
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
    in
    {
      homeConfigurations."root" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home.nix ];
      };
    };
}
