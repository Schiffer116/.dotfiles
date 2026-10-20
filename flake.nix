{
  description = "schiffer: Arch laptop (home-manager)";

  inputs = {
    # Pinned by flake.lock.
    # Update deliberately: `nix flake update`, then commit the lock.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager"; # master tracks nixos-unstable
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true; # terraform (BSL), unrar
      };
    in
    {
      # Laptop (Arch): home-manager switch --flake ~/.dotfiles#schiffer@archlinux
      homeConfigurations."schiffer@archlinux" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./nix/home.nix ];
      };

      # Tools for working on this repo: nix develop
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          nil
          nixfmt
          shellcheck
        ];
      };

      formatter.${system} = pkgs.nixfmt-tree;
    };
}
