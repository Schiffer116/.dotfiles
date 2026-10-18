# Shared by every machine: identity, XDG, and the `link` helper the other modules use.
{ config, ... }:
{
  home.username = "schiffer";
  home.homeDirectory = "/home/schiffer";
  home.stateVersion = "26.05"; # set once; never bump casually
  programs.home-manager.enable = true;
  xdg.enable = true;

  # Out-of-store links: the file stays in ~/.dotfiles, so edits apply without a rebuild
  # and app-written files (lazy-lock.json, herdr config) keep working.
  # The repo must be cloned at ~/.dotfiles on every machine.
  lib.dotfiles.link =
    path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/${path}";
}
