# herdr and Claude Code config. Claude Code itself is installed with its native
# installer (self-updating); on the box it runs through nix-ld.
{ config, pkgs, ... }:
let
  link = config.lib.dotfiles.link;
in
{
  home.packages = [ pkgs.herdr ];

  # `npm i -g` (the *-axi fleet tools) installs into ~/.local, not the read-only Nix store.
  home.sessionVariables.NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.local";

  # Only config.toml: herdr writes logs and sessions next to it, which must stay out of the repo.
  xdg.configFile."herdr/config.toml".source = link ".config/herdr/config.toml";

  home.file.".claude/keybindings.json".source = link ".claude/keybindings.json";
  home.file.".claude/hooks/speak-notify.sh".source = link ".claude/hooks/speak-notify.sh";
  # Claude Code reads user instructions from ~/.claude/CLAUDE.md, not ~/.CLAUDE.md.
  home.file.".claude/CLAUDE.md".source = link ".CLAUDE.md";
  # ~/.claude/settings.json is linked by stow on the laptop, so Claude Code's in-place
  # rewrites land in the repo and show up in git diff.
}
