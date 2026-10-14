# Laptop (Arch): standalone home-manager. pacman keeps the kernel, drivers, services,
# the Hyprland session and GUI apps; this owns the dev environment.
{ ... }:
{
  imports = [
    ../home/common.nix
    ../home/cli.nix
    ../home/dev.nix
    ../home/shell.nix
    ../home/editor.nix
    ../home/agents.nix
  ];

  targets.genericLinux.enable = true; # XDG_DATA_DIRS etc. on a non-NixOS host
  targets.genericLinux.gpu.enable = false; # GUI/GPU apps stay on pacman
}
