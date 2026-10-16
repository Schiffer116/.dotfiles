# Laptop (Arch): standalone home-manager. pacman keeps the kernel, drivers, services,
# the Hyprland session and GUI apps; this owns the dev environment.
{ pkgs, ... }:
{
  imports = [
    ../home/common.nix
    ../home/cli.nix
    ../home/dev.nix
    ../home/shell.nix
    ../home/editor.nix
    ../home/agents.nix
  ];

  # Volume and per-output brightness daemon for the Hyprland desktop (scripts/levelctl).
  home.packages = [
    (pkgs.buildGoModule {
      pname = "levelctl";
      version = "0.1.0";
      src = ../../scripts/levelctl;
      vendorHash = null; # standard library only
    })
  ];

  targets.genericLinux.enable = true; # XDG_DATA_DIRS etc. on a non-NixOS host
  targets.genericLinux.gpu.enable = false; # GUI/GPU apps stay on pacman
}
