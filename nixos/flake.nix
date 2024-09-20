{
  description = "Flaked";

  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05";
  };

  outputs = { nixpkgs-stable, ... }@inputs:
    let
      lib = nixpkgs-stable.lib;
      system = "x86_64-linux";
    in {
      nixosConfigurations = {
        schiffer = lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
          };
          modules = [ ./configuration.nix ];
        };
      };
    };
}
