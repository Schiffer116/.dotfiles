#!/usr/bin/env sh

set -e
cd "$HOME"/.dotfiles/nixos/
nvim configuration.nix
# git diff -U0 *.nix
# echo "NixOS Rebuilding..."
sudo nixos-rebuild switch --flake .#schiffer | tee nixos-switch.log ||
(grep --color error < nixos-switch.log)
# gen=$(nixos-rebuild list-generations | grep current)
# git commit -am "$gen"
cd -
