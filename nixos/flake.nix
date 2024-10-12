{
  description = "Flaked";

  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs-stable, nixpkgs-unstable, ... }: {
    nixosConfigurations = {
      schiffer = nixpkgs-stable.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = {
          upkgs = import nixpkgs-unstable {
              inherit system;
              config.allowUnfree = true;
          };
        };
        modules = [ ./configuration.nix ];
      };
    };
  };
}
