# Hyprland desktop. Configs are linked like the dev env's; the compositor,
# GUI apps (GL), and tools needing udev rules, setuid or PAM (brightnessctl, ddcutil,
# hyprlock, hypridle) stay on pacman. Daemons start from hyprland.lua, not systemd units.
{ config, pkgs, ... }:
let
  link = config.lib.dotfiles.link;
in
{
  xdg.configFile."hypr".source = link ".config/hypr";
  xdg.configFile."eww".source = link ".config/eww";
  xdg.configFile."mako".source = link ".config/mako";
  xdg.configFile."kitty/kitty.conf".source = link ".config/kitty/kitty.conf";

  # On PATH via .zshenv; Hyprland binds and eww call these by bare name.
  home.file."scripts".source = link "scripts";
  # Wallpapers are tracked; screenshots land here too and stay untracked.
  home.file."Pictures".source = link "Pictures";

  home.packages = with pkgs; [
    # Volume and per-output brightness daemon (scripts/levelctl).
    (buildGoModule {
      pname = "levelctl";
      version = "0.1.0";
      src = ../../scripts/levelctl;
      vendorHash = null; # standard library only
    })
    # Wayland CLI tools the scripts and binds call.
    cliphist
    wl-clipboard
    wtype
    grim
    slurp
    playerctl
    libnotify
    imagemagick
  ];
}
