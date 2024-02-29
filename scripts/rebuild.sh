#!/usr/bin/env sh

set -e
pushd $HOME/.dotfiles/nixos/ > /dev/null
nvim configuration.nix
# git diff -U0 *.nix
echo "NixOS Rebuilding..."
sudo nixos-rebuild switch --flake .#schiffer &> nixos-switch.log || (
   cat nixos-switch.log | grep --color error && false)
# gen=$(nixos-rebuild list-generations | grep current)
# git commit -am "$gen"
popd > /dev/null
