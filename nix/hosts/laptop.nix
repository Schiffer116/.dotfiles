# Laptop (Arch): standalone home-manager. pacman keeps the kernel, drivers, services,
# the Hyprland compositor and GUI apps; this owns every config file in $HOME.
{ ... }:
{
  imports = [
    ../home/common.nix
    ../home/cli.nix
    ../home/dev.nix
    ../home/shell.nix
    ../home/editor.nix
    ../home/agents.nix
    ../home/desktop.nix
  ];

  targets.genericLinux.enable = true; # XDG_DATA_DIRS etc. on a non-NixOS host
  targets.genericLinux.gpu.enable = false; # GUI/GPU apps stay on pacman
}
