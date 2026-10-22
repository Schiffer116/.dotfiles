# Toolchains, cloud CLIs and git. C compilers stay with pacman so builds keep
# finding the OS headers.
{ lib, pkgs, ... }:
let
  # 1.26.10 fixes net/http vulns the Berthier Console is exposed to. Drop this once
  # nixos-unstable's go is >= 1.26.10.
  go = pkgs.go.overrideAttrs rec {
    version = "1.26.10";
    src = pkgs.fetchurl {
      url = "https://go.dev/dl/go${version}.src.tar.gz";
      hash = "sha256-/WPog7ovK/ypPBZGsx6+9j4rHk0rMXyXidl2po2B828=";
    };
  };
in
{
  home.packages = with pkgs; [
    go
    nodejs
    pnpm
    uv
    rustup
    awscli2
    terraform
    # minikube also ships bin/kubectl (a shim); prefer the real one.
    (lib.hiPrio kubectl)
    minikube
    act
    gh
    postgresql
  ];

  programs.git = {
    enable = true;
    lfs.enable = true;
    settings.user = {
      name = "Schiffer116";
      email = "khanhpg5@gmail.com";
    };
  };
}
