# dotfiles
Configuration for Linux related software

## Nix

The dev environment (shell, editor, CLI and dev tools, agent config) and desktop configs are a flake with home-manager.
Config files stay in this repo and are linked into place, so edits apply without a rebuild. The repo must be cloned at `~/.dotfiles`.

- Laptop (Arch, Nix installed): `home-manager switch --flake ~/.dotfiles#schiffer@archlinux`. This links the dev env and the Hyprland desktop configs; pacman keeps the compositor, GUI apps and system services.
  home-manager refuses to replace existing files: remove any old links (e.g. from GNU Stow) at the paths it reports, then switch again.
- Cloud dev box (NixOS on EC2): see [infra/aws-dev](infra/aws-dev/README.md).
- Update the pinned nixpkgs: `nix flake update`, then commit `flake.lock`.
