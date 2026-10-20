# Toolchains, cloud CLIs and git. C compilers stay with pacman so builds keep
# finding the OS headers.
{ lib, pkgs, ... }:
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
