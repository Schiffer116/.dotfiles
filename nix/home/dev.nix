# Toolchains, cloud CLIs and git. C compilers stay with the OS (pacman on Arch,
# the system profile on the box) so builds keep finding the OS headers.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    go
    nodejs
    pnpm
    uv
    rustup
    awscli2
    terraform
    kubectl
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
