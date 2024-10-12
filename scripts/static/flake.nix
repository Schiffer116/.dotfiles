{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  };

  outputs = { self, nixpkgs }:

  let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
  in {
    devShells.x86_64-linux.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        python312
        python312Packages.ipykernel
        python312Packages.pip
        python312Packages.numpy
        python312Packages.pandas
        python312Packages.matplotlib
      ];
    };
  };
}
