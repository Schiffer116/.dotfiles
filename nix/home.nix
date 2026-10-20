# Arch laptop, standalone home-manager: identity, XDG, the `link` helper and the topic
# modules. pacman keeps the kernel, drivers, services, the Hyprland compositor and GUI
# apps; this owns every config file in $HOME.
{ config, ... }:
{
  imports = [
    ./home/shell.nix
    ./home/editor.nix
    ./home/agents.nix
    ./home/cli.nix
    ./home/dev.nix
    ./home/desktop.nix
  ];

  home.username = "schiffer";
  home.homeDirectory = "/home/schiffer";
  home.stateVersion = "26.05"; # set once; never bump casually
  programs.home-manager.enable = true;
  xdg.enable = true;

  targets.genericLinux.enable = true; # XDG_DATA_DIRS etc. on a non-NixOS host
  targets.genericLinux.gpu.enable = false; # GUI/GPU apps stay on pacman

  # Out-of-store links: the file stays in ~/.dotfiles, so edits apply without a rebuild
  # and app-written files (lazy-lock.json, herdr config) keep working.
  # The repo must be cloned at ~/.dotfiles.
  lib.dotfiles.link =
    path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/${path}";
}
