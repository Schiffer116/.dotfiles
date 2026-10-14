# home-manager on the box: the same modules as the laptop, without the desktop.
{ ... }:
{
  imports = [
    ../../home/common.nix
    ../../home/cli.nix
    ../../home/dev.nix
    ../../home/shell.nix
    ../../home/editor.nix
    ../../home/agents.nix
  ];
}
