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

  # Claude Code: everything under .claude/ in the repo, linked file by file. ~/.claude
  # itself stays a real directory because Claude Code keeps sessions, history and
  # credentials there, and herdr installs its own hook into ~/.claude/hooks.
  # Claude Code rewrites settings.json in place (/config, permission grants), so
  # those changes land in the repo and show up in git diff.
  home.file = builtins.listToAttrs (
    map
      (path: {
        name = ".claude/${path}";
        value.source = link ".claude/${path}";
      })
      [
        "CLAUDE.md"
        "settings.json"
        "keybindings.json"
        "statusline.sh"
        "skills/no-mistakes"
        "skills/notify-user"
      ]
  );
}
