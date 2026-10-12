# dotfiles
Configuration for Linux related software

## Nix

The dev environment (shell, editor, CLI and dev tools, agent config) is a flake with home-manager.
Config files stay in this repo and are linked into place, so edits apply without a rebuild. The repo must be cloned at `~/.dotfiles`.

- Laptop (Arch, Nix installed): `home-manager switch --flake ~/.dotfiles#schiffer@archlinux`. pacman keeps the desktop and system services; stow still links the desktop configs.
- Cloud dev box (NixOS on EC2): see [infra/aws-dev](infra/aws-dev/README.md).
- Update the pinned nixpkgs: `nix flake update`, then commit `flake.lock`.
